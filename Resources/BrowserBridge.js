(function () {
  "use strict";

  if (window.__tonyGrassBridgeInstalled) return;
  window.__tonyGrassBridgeInstalled = true;

  var bound = new WeakSet();
  var activeVideo = null;
  var lastStateAt = 0;
  var candidates = [];
  var seen = new Set();
  var button = null;
  var toast = null;
  var cinemaVideo = null;
  var cinemaSurface = null;
  var cinemaSnapshot = null;
  var cinemaToggleButton = null;
  var hostCinemaFrame = null;
  var hostCinemaStyle = null;
  var hostCinemaScroll = null;
  var originalFetch = window.fetch;
  var originalXHROpen = XMLHttpRequest.prototype.open;
  var mediaExtension = /\.(?:mp4|m4v|webm|mov|mkv|avi|mp3|m4a|aac|ogg|oga|opus|wav|flac)(?:$|[?#])/i;
  var hlsURL = /(?:\.m3u8(?:$|[?#])|\/hls(?:$|[?#])|playlist\/master)/i;
  var dashURL = /\.mpd(?:$|[?#])/i;
  var fragmentURL = /\.(?:ts|m4s|cmfv|cmfa|key)(?:$|[?#])/i;

  function post(payload) {
    try {
      window.webkit.messageHandlers.tonyBridge.postMessage(payload);
    } catch (_) {}
  }

  function finite(value) {
    return Number.isFinite(value) ? value : 0;
  }

  function absoluteURL(raw) {
    if (!raw || typeof raw !== "string") return null;
    try {
      var value = new URL(raw, location.href);
      return /^https?:$/i.test(value.protocol) ? value.href : null;
    } catch (_) {
      return null;
    }
  }

  function mediaKind(url) {
    if (!url || fragmentURL.test(url)) return null;
    if (hlsURL.test(url)) return "hls";
    if (dashURL.test(url)) return "dash";
    if (mediaExtension.test(url)) return "direct";
    return null;
  }

  function remember(raw, source, force) {
    var url = absoluteURL(raw);
    var kind = mediaKind(url);
    if (!url || !kind || (!force && seen.has(url))) return;
    seen.add(url);
    candidates.push({ url: url, kind: kind, source: source || "page", seenAt: Date.now() });
    if (candidates.length > 100) candidates.splice(0, candidates.length - 100);
  }

  function rememberVideo(video, force) {
    if (!video) return;
    [
      video.currentSrc,
      video.src,
      video.getAttribute("src"),
      video.getAttribute("data-src"),
      video.getAttribute("data-url"),
      video.getAttribute("data-video-src"),
      video.getAttribute("data-hls"),
      video.getAttribute("data-m3u8")
    ].forEach(function (value) { remember(value, "video", force); });
    video.querySelectorAll("source").forEach(function (source) {
      remember(source.currentSrc || source.src || source.getAttribute("src"), "source", force);
    });
  }

  function mediaState(video, force) {
    if (!video) return;
    var now = Date.now();
    if (!force && now - lastStateAt < 350) return;
    lastStateAt = now;
    var currentSource = video.currentSrc || video.src || "";
    var nativeURL = absoluteURL(currentSource);
    if (!nativeURL || !mediaKind(nativeURL)) {
      var candidate = bestCandidate();
      nativeURL = candidate && candidate.url ? candidate.url : null;
    }
    post({
      type: "state",
      currentTime: finite(video.currentTime),
      duration: finite(video.duration),
      paused: !!video.paused,
      ended: !!video.ended,
      rate: finite(video.playbackRate) || 1,
      pip: (document.pictureInPictureElement === video) ||
        video.webkitPresentationMode === "picture-in-picture",
      pipAvailable: !!document.pictureInPictureEnabled ||
        (typeof video.webkitSupportsPresentationMode === "function" &&
          video.webkitSupportsPresentationMode("picture-in-picture")),
      fullscreen: !!document.fullscreenElement || !!video.webkitDisplayingFullscreen ||
        video.webkitPresentationMode === "fullscreen",
      title: document.title || "小草视频",
      src: currentSource || location.href,
      nativeURL: nativeURL || "",
      pageURL: location.href,
      userAgent: navigator.userAgent || ""
    });
  }

  function bindVideo(video) {
    if (!video || bound.has(video)) return;
    bound.add(video);
    [
      "loadstart", "loadedmetadata", "durationchange", "play", "pause", "ended",
      "ratechange", "seeking", "seeked", "webkitpresentationmodechanged",
      "webkitbeginfullscreen", "webkitendfullscreen", "enterpictureinpicture",
      "leavepictureinpicture"
    ].forEach(function (eventName) {
      video.addEventListener(eventName, function () {
        activeVideo = video;
        rememberVideo(video, true);
        mediaState(video, true);
      }, true);
    });
    video.addEventListener("timeupdate", function () {
      activeVideo = video;
      mediaState(video, false);
    }, true);
    rememberVideo(video, false);
    if (!video.paused || video.currentTime > 0) {
      activeVideo = video;
      mediaState(video, true);
    }
  }

  function scan(root) {
    if (!root) return;
    if (root.tagName === "VIDEO" || root.tagName === "AUDIO") bindVideo(root);
    if (root.querySelectorAll) root.querySelectorAll("video,audio").forEach(bindVideo);
  }

  function scanPerformance() {
    try {
      performance.getEntriesByType("resource").forEach(function (entry) {
        remember(entry.name, "performance", false);
      });
    } catch (_) {}
  }

  function currentVideo() {
    if (activeVideo && document.contains(activeVideo)) return activeVideo;
    var videos = Array.from(document.querySelectorAll("video,audio"));
    activeVideo = videos.find(function (video) { return !video.paused && !video.ended; }) || videos[0] || null;
    return activeVideo;
  }

  function isMediaFullscreen(video) {
    return !!document.fullscreenElement || !!(video && video.webkitDisplayingFullscreen) ||
      !!(video && video.webkitPresentationMode === "fullscreen");
  }

  function fullscreenIconMarkup(exit) {
    var path = exit
      ? "M4 9h5V4 M20 9h-5V4 M4 15h5v5 M20 15h-5v5"
      : "M9 4H4v5 M15 4h5v5 M9 20H4v-5 M15 20h5v-5";
    return '<svg viewBox="0 0 24 24" aria-hidden="true" fill="none" ' +
      'stroke="currentColor" stroke-width="2.2" stroke-linecap="round" ' +
      'stroke-linejoin="round"><path d="' + path + '"/></svg>';
  }

  function updateFullscreenButton(button, exit) {
    if (!button) return;
    if (button.__tonyFullscreenExit !== !!exit) {
      button.__tonyFullscreenExit = !!exit;
      button.innerHTML = fullscreenIconMarkup(exit);
    }
    button.setAttribute("aria-label", exit ? "退出全屏" : "全屏");
    button.setAttribute("title", exit ? "退出全屏" : "全屏");
  }

  function enterNativeVideoFullscreen(video) {
    if (!video) return false;
    try {
      // Apple documents this as the native full-screen entry point for a
      // video element. It must be the first call made by the trusted click.
      if (typeof video.webkitEnterFullscreen === "function" &&
          video.webkitSupportsFullscreen !== false) {
        video.webkitEnterFullscreen();
        return true;
      }
      if (typeof video.webkitEnterFullScreen === "function" &&
          video.webkitSupportsFullscreen !== false) {
        video.webkitEnterFullScreen();
        return true;
      }
      if (typeof video.webkitSetPresentationMode === "function" &&
          (typeof video.webkitSupportsPresentationMode !== "function" ||
            video.webkitSupportsPresentationMode("fullscreen"))) {
        video.webkitSetPresentationMode("fullscreen");
        return true;
      }
      if (video.requestFullscreen) {
        var request = video.requestFullscreen();
        if (request && request.catch) request.catch(function () {});
        return true;
      }
      if (video.webkitRequestFullscreen) {
        video.webkitRequestFullscreen();
        return true;
      }
    } catch (_) {}
    return false;
  }

  function handleFullscreenClick(event) {
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();
    var player = event.currentTarget.closest(".dplayer");
    var video = event.currentTarget.__tonyVideo ||
      (player && player.querySelector("video")) || currentVideo();
    if (!video) return;
    activeVideo = video;
    var wasCinemaFullscreen = cinemaVideo === video;
    var wasFullscreen = wasCinemaFullscreen || isMediaFullscreen(video);
    if (wasCinemaFullscreen) {
      post({ type: "fullscreenRequest" });
      return;
    }
    if (!wasFullscreen) {
      // This runs inside the trusted click itself. Asking WebKit for its native
      // video presentation here preserves user activation, letting AVKit own
      // both the on-screen controls and the Touch Bar exactly as it does for a
      // normal native player. Native requests made later by the app process no
      // longer carry this activation and are rejected by many embedded sites.
      var token = {};
      video.__tonyNativeFullscreenToken = token;
      var requested = enterNativeVideoFullscreen(video);
      setTimeout(function () {
        if (video.__tonyNativeFullscreenToken !== token) return;
        video.__tonyNativeFullscreenToken = null;
        if (!isMediaFullscreen(video) && cinemaVideo !== video) {
          post({ type: "fullscreenRequest" });
        }
      }, requested ? 900 : 0);
      return;
    }
    try {
      if (document.fullscreenElement && document.exitFullscreen) document.exitFullscreen();
      else if (typeof video.webkitExitFullscreen === "function") video.webkitExitFullscreen();
      else if (typeof video.webkitSetPresentationMode === "function") video.webkitSetPresentationMode("inline");
    } catch (_) {}
  }

  function cleanEmbeddedPlayerChrome() {
    var host = String(location.hostname || "").toLowerCase();
    if (host !== "she1919.com" && !host.endsWith(".she1919.com")) return;

    // This player prepends a viewport-sized advertising link disguised as a
    // play button. It sits above DPlayer and navigates away instead of playing.
    // The original iOS experience exposes the real media control directly.
    window.__popupPending = false;
    document.querySelectorAll('a[href*="/tiaozhuan.html"]').forEach(function (link) {
      var style = getComputedStyle(link);
      var rect = link.getBoundingClientRect();
      var coversPlayer = style.position === "fixed" &&
        rect.width >= window.innerWidth * 0.75 && rect.height >= window.innerHeight * 0.75;
      if (coversPlayer) link.remove();
    });
    document.querySelectorAll(".player-side-panel").forEach(function (panel) {
      panel.style.setProperty("display", "none", "important");
    });
    if (!document.getElementById("__tonyPlayerChromeFix")) {
      var styleFix = document.createElement("style");
      styleFix.id = "__tonyPlayerChromeFix";
      styleFix.textContent =
        ".dplayer-playing .dplayer-mobile-play," +
        ".dplayer-playing .dplayer-bezel{" +
        "display:none!important;opacity:0!important;visibility:hidden!important;pointer-events:none!important}" +
        ".dplayer-playing video{cursor:none!important}" +
        ".dplayer .dplayer-controller .dplayer-icons-right .dplayer-full{" +
        "display:inline-flex!important;visibility:visible!important;opacity:1!important;" +
        "position:absolute!important;right:4px!important;bottom:0!important;z-index:999999!important;" +
        "width:42px!important;height:38px!important;margin:0!important;padding:0!important;" +
        "border:0!important;background:transparent!important;color:#fff!important;" +
        "align-items:center!important;justify-content:center!important;pointer-events:auto!important;cursor:pointer!important}" +
        ".dplayer .dplayer-controller .dplayer-icons-right .dplayer-full svg{" +
        "display:block!important;width:21px!important;height:21px!important;" +
        "fill:none!important;stroke:currentColor!important}" +
        "html[data-tony-cinema=\"1\"] .dplayer .dplayer-controller .dplayer-icons-right .dplayer-full{" +
        "display:none!important}" +
        ".tony-cinema-fullscreen-toggle{" +
        "all:unset!important;box-sizing:border-box!important;position:fixed!important;" +
        "right:8px!important;bottom:3px!important;z-index:2147483647!important;" +
        "width:48px!important;height:42px!important;display:flex!important;" +
        "align-items:center!important;justify-content:center!important;" +
        "color:#fff!important;background:rgba(0,0,0,.18)!important;" +
        "border-radius:5px!important;opacity:1!important;visibility:visible!important;" +
        "pointer-events:auto!important;cursor:pointer!important}" +
        ".tony-cinema-fullscreen-toggle:hover{background:rgba(0,0,0,.42)!important}" +
        ".tony-cinema-fullscreen-toggle svg{" +
        "display:block!important;width:24px!important;height:24px!important;" +
        "fill:none!important;stroke:currentColor!important}";
      (document.head || document.documentElement).appendChild(styleFix);
    }

    document.querySelectorAll(".dplayer").forEach(function (player) {
      var right = player.querySelector(".dplayer-controller .dplayer-icons-right");
      if (!right) return;
      var fullscreen = right.querySelector(".dplayer-full");
      if (!fullscreen) {
        fullscreen = document.createElement("button");
        fullscreen.type = "button";
        fullscreen.className = "dplayer-icon dplayer-full";
        right.appendChild(fullscreen);
      }
      fullscreen.setAttribute("data-tony-fullscreen", "1");
      updateFullscreenButton(fullscreen, cinemaVideo === (player.querySelector("video") || activeVideo) ||
        isMediaFullscreen(player.querySelector("video") || activeVideo));
      if (!fullscreen.__tonyFullscreenBound) {
        fullscreen.__tonyFullscreenBound = true;
        fullscreen.addEventListener("click", handleFullscreenClick, true);
      }
    });
  }

  function installCinemaToggle(video, surface) {
    if (!video) return;
    if (!cinemaToggleButton) {
      cinemaToggleButton = document.createElement("button");
      cinemaToggleButton.type = "button";
      cinemaToggleButton.className = "tony-cinema-fullscreen-toggle";
      cinemaToggleButton.setAttribute("data-tony-fullscreen", "1");
      cinemaToggleButton.addEventListener("click", handleFullscreenClick, true);
    }
    cinemaToggleButton.__tonyVideo = video;
    updateFullscreenButton(cinemaToggleButton, true);
    var target = surface && surface.tagName !== "VIDEO"
      ? surface
      : (document.body || document.documentElement);
    if (cinemaToggleButton.parentNode !== target) target.appendChild(cinemaToggleButton);
  }

  function removeCinemaToggle() {
    if (!cinemaToggleButton) return;
    cinemaToggleButton.__tonyVideo = null;
    cinemaToggleButton.remove();
    cinemaToggleButton = null;
  }

  function setBridgeOverlaysHidden(hidden) {
    if (button) button.style.setProperty("display", hidden ? "none" : "flex", "important");
    if (toast) toast.style.setProperty("display", hidden ? "none" : "block", "important");
  }

  function setCinema(video, enabled) {
    if (!enabled) {
      if (cinemaVideo && cinemaSnapshot) {
        if (cinemaSnapshot.videoStyle === null) cinemaVideo.removeAttribute("style");
        else cinemaVideo.setAttribute("style", cinemaSnapshot.videoStyle);
        if (cinemaSurface) {
          if (cinemaSnapshot.surfaceStyle === null) cinemaSurface.removeAttribute("style");
          else cinemaSurface.setAttribute("style", cinemaSnapshot.surfaceStyle);
        }
        document.documentElement.style.overflow = cinemaSnapshot.htmlOverflow;
        if (document.body) document.body.style.overflow = cinemaSnapshot.bodyOverflow;
      }
      document.querySelectorAll("[data-tony-fullscreen]").forEach(function (item) {
        updateFullscreenButton(item, false);
      });
      document.documentElement.removeAttribute("data-tony-cinema");
      removeCinemaToggle();
      cinemaVideo = null;
      cinemaSurface = null;
      cinemaSnapshot = null;
      setBridgeOverlaysHidden(false);
      return;
    }
    if (!video) return;
    if (cinemaVideo && cinemaVideo !== video) setCinema(cinemaVideo, false);
    var surface = video.closest(".dplayer") || video;
    if (!cinemaSnapshot) {
      cinemaSnapshot = {
        videoStyle: video.getAttribute("style"),
        surfaceStyle: surface.getAttribute("style"),
        htmlOverflow: document.documentElement.style.overflow,
        bodyOverflow: document.body ? document.body.style.overflow : ""
      };
    }
    cinemaVideo = video;
    cinemaSurface = surface;
    document.documentElement.setAttribute("data-tony-cinema", "1");
    setBridgeOverlaysHidden(true);
    document.documentElement.style.overflow = "hidden";
    if (document.body) document.body.style.overflow = "hidden";
    [
      ["position", "fixed"], ["inset", "0"], ["width", "100vw"],
      ["height", "100vh"], ["max-width", "none"], ["max-height", "none"],
      ["margin", "0"], ["object-fit", "contain"], ["background", "black"],
      ["z-index", "2147483646"]
    ].forEach(function (item) { surface.style.setProperty(item[0], item[1], "important"); });
    if (surface !== video) {
      [
        ["width", "100%"], ["height", "100%"], ["max-width", "none"],
        ["max-height", "none"], ["margin", "0"], ["object-fit", "contain"],
        ["background", "black"]
      ].forEach(function (item) { video.style.setProperty(item[0], item[1], "important"); });
    }
    installCinemaToggle(video, surface);
    document.querySelectorAll("[data-tony-fullscreen]").forEach(function (item) {
      updateFullscreenButton(item, true);
    });
  }

  function setHostCinema(enabled) {
    if (!enabled) {
      if (hostCinemaFrame) {
        if (hostCinemaStyle === null) hostCinemaFrame.removeAttribute("style");
        else hostCinemaFrame.setAttribute("style", hostCinemaStyle);
      }
      if (hostCinemaScroll) window.scrollTo(hostCinemaScroll.x, hostCinemaScroll.y);
      hostCinemaFrame = null;
      hostCinemaStyle = null;
      hostCinemaScroll = null;
      setBridgeOverlaysHidden(false);
      return;
    }
    var frames = Array.from(document.querySelectorAll("iframe")).filter(function (frame) {
      var rect = frame.getBoundingClientRect();
      return rect.width >= 240 && rect.height >= 120 && rect.bottom > 0 && rect.right > 0;
    });
    frames.sort(function (a, b) {
      var ar = a.getBoundingClientRect();
      var br = b.getBoundingClientRect();
      return (br.width * br.height) - (ar.width * ar.height);
    });
    var frame = frames[0];
    if (!frame) return;
    // windowDidEnterFullScreen asks the top frame to apply cinema mode again.
    // Do not replace the original snapshot with the already-expanded style,
    // otherwise exiting fullscreen restores the fullscreen CSS and leaves the
    // page stuck in a half-fullscreen state.
    if (hostCinemaFrame === frame) return;
    if (hostCinemaFrame) setHostCinema(false);
    hostCinemaFrame = frame;
    hostCinemaStyle = frame.getAttribute("style");
    hostCinemaScroll = { x: window.scrollX, y: window.scrollY };
    setBridgeOverlaysHidden(true);
    [
      ["position", "fixed"], ["inset", "0"], ["width", "100vw"],
      ["height", "100vh"], ["max-width", "none"], ["max-height", "none"],
      ["margin", "0"], ["border", "0"], ["background", "black"],
      ["z-index", "2147483645"]
    ].forEach(function (item) { frame.style.setProperty(item[0], item[1], "important"); });
  }

  function bestCandidate() {
    var video = currentVideo();
    if (video) rememberVideo(video, true);
    scan(document);
    scanPerformance();

    var direct = video && absoluteURL(video.currentSrc || video.src);
    if (direct && mediaKind(direct)) {
      return { url: direct, kind: mediaKind(direct), source: "active-video" };
    }

    var weighted = candidates.map(function (item, index) {
      var score = item.kind === "hls" ? 300 : item.kind === "dash" ? 240 : 160;
      if (/master|manifest|index/i.test(item.url)) score += 35;
      if (item.source === "video" || item.source === "source") score += 25;
      score += index / Math.max(candidates.length, 1);
      return { item: item, score: score };
    });
    weighted.sort(function (a, b) { return b.score - a.score; });
    return weighted.length ? weighted[0].item : null;
  }

  function showToast(message, isError) {
    if (!toast) return;
    toast.textContent = message;
    toast.style.background = isError ? "rgba(163,32,45,.95)" : "rgba(22,25,31,.95)";
    toast.style.opacity = "1";
    clearTimeout(toast.__timer);
    toast.__timer = setTimeout(function () { toast.style.opacity = "0"; }, isError ? 6500 : 3600);
  }

  function setButton(label, busy, title) {
    if (!button) return;
    button.textContent = label || "⇩";
    button.disabled = !!busy;
    button.title = title || "用 VidCatch 下载当前视频";
    button.style.opacity = busy ? ".78" : "1";
  }

  function refreshAvailability() {
    if (!button || button.disabled) return;
    var candidate = bestCandidate();
    button.style.filter = candidate ? "none" : "grayscale(1)";
    button.title = candidate ? "用 VidCatch 下载当前视频" : "请先播放视频";
  }

  function requestDownload(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }
    var candidate = bestCandidate();
    if (!candidate) {
      showToast("暂未检测到视频地址，请先开始播放再点下载", true);
      return;
    }
    setButton("…", true, "正在连接 VidCatch");
    showToast("正在交给 VidCatch 分析…", false);
    post({
      type: "download",
      url: candidate.url,
      kind: candidate.kind,
      source: candidate.source || "page",
      title: (document.title || "小草视频").replace(/\s+/g, " ").trim(),
      pageUrl: location.href,
      userAgent: navigator.userAgent || ""
    });
  }

  window.__tonyVidCatchStatus = function (payload) {
    payload = payload || {};
    var status = String(payload.status || "");
    var message = String(payload.message || "");
    var progress = Number(payload.progress || 0);
    if (status === "probing" || status === "queued") {
      setButton("…", true, message || "正在分析");
    } else if (status === "downloading") {
      setButton(progress > 0 ? Math.min(99, Math.round(progress)) + "%" : "↓", true, message || "正在下载");
    } else if (status === "complete") {
      setButton("✓", false, "下载完成");
      showToast(message || "视频已保存到下载文件夹", false);
      setTimeout(function () { setButton("⇩", false); refreshAvailability(); }, 2600);
    } else if (status === "error") {
      setButton("!", false, "下载失败");
      showToast(message || "下载失败", true);
      setTimeout(function () { setButton("⇩", false); refreshAvailability(); }, 3200);
    } else if (status === "cancelled") {
      setButton("⇩", false, "下载已取消");
      showToast(message || "下载已取消", true);
      refreshAvailability();
    }
  };

  function installUI() {
    if (!document.documentElement || document.getElementById("__tonyVidCatchButton")) return;
    var host = document.body || document.documentElement;
    button = document.createElement("button");
    button.id = "__tonyVidCatchButton";
    button.type = "button";
    button.textContent = "⇩";
    button.setAttribute("aria-label", "下载当前视频");
    button.style.cssText = [
      "all:initial", "box-sizing:border-box", "position:fixed", "z-index:2147483647",
      "right:18px", "bottom:78px", "width:54px", "height:54px", "border-radius:27px",
      "border:1px solid rgba(255,255,255,.3)",
      "background:linear-gradient(145deg,rgba(52,130,255,.98),rgba(34,92,220,.98))",
      "color:white", "font:700 18px -apple-system,BlinkMacSystemFont,sans-serif",
      "display:flex", "align-items:center", "justify-content:center", "text-align:center",
      "box-shadow:0 7px 22px rgba(0,0,0,.35)", "cursor:pointer", "user-select:none"
    ].join(";");
    button.addEventListener("click", requestDownload, true);

    toast = document.createElement("div");
    toast.id = "__tonyVidCatchToast";
    toast.style.cssText = [
      "all:initial", "box-sizing:border-box", "position:fixed", "z-index:2147483647",
      "right:18px", "bottom:142px", "max-width:min(380px,calc(100vw - 36px))",
      "padding:10px 13px", "border-radius:10px", "background:rgba(22,25,31,.95)",
      "color:white", "font:500 13px/1.35 -apple-system,BlinkMacSystemFont,sans-serif",
      "box-shadow:0 5px 18px rgba(0,0,0,.32)", "opacity:0", "pointer-events:none",
      "transition:opacity .18s ease"
    ].join(";");
    host.appendChild(toast);
    host.appendChild(button);
    refreshAvailability();
  }

  function frameHasDownloadableMedia() {
    return !!document.querySelector("video,audio") || !!bestCandidate();
  }

  window.addEventListener("message", function (event) {
    var data = event.data;
    if (!data || data.__tonyGrassCommand !== true) return;
    var video = currentVideo();
    if (data.command === "hostCinema") {
      setHostCinema(!!data.value);
      return;
    }
    if (data.command === "cinema") {
      setCinema(video, !!data.value);
      mediaState(video, true);
      return;
    }
    if (data.command === "windowFullscreen") {
      post({ type: "windowFullscreen" });
      return;
    }
    if (!video) return;
    activeVideo = video;
    if (data.command === "play") {
      var directPlay = video.play();
      if (directPlay && directPlay.catch) directPlay.catch(function () {});
    } else if (data.command === "pause") {
      video.pause();
    } else if (data.command === "toggle") {
      if (video.paused) {
        var play = video.play();
        if (play && play.catch) play.catch(function () {});
      } else {
        video.pause();
      }
    } else if (data.command === "seek" && Number.isFinite(data.value)) {
      var target = Math.max(0, data.value);
      if (Number.isFinite(video.duration)) target = Math.min(target, video.duration);
      video.currentTime = target;
    } else if (data.command === "pip") {
      if (typeof video.webkitSetPresentationMode === "function" &&
          typeof video.webkitSupportsPresentationMode === "function" &&
          video.webkitSupportsPresentationMode("picture-in-picture")) {
        video.webkitSetPresentationMode(
          video.webkitPresentationMode === "picture-in-picture" ? "inline" : "picture-in-picture"
        );
      } else if (document.pictureInPictureElement && document.exitPictureInPicture) {
        var exitPip = document.exitPictureInPicture();
        if (exitPip && exitPip.catch) exitPip.catch(function () {});
      } else if (video.requestPictureInPicture) {
        var enterPip = video.requestPictureInPicture();
        if (enterPip && enterPip.catch) enterPip.catch(function () {});
      }
    } else if (data.command === "fullscreen") {
      var isFull = !!document.fullscreenElement || !!video.webkitDisplayingFullscreen ||
        video.webkitPresentationMode === "fullscreen";
      if (isFull) {
        if (document.fullscreenElement && document.exitFullscreen) document.exitFullscreen();
        else if (typeof video.webkitExitFullscreen === "function") video.webkitExitFullscreen();
        else if (typeof video.webkitSetPresentationMode === "function") video.webkitSetPresentationMode("inline");
      } else if (typeof video.webkitSetPresentationMode === "function" &&
          (typeof video.webkitSupportsPresentationMode !== "function" ||
            video.webkitSupportsPresentationMode("fullscreen"))) {
        video.webkitSetPresentationMode("fullscreen");
      } else if (typeof video.webkitEnterFullscreen === "function") {
        video.webkitEnterFullscreen();
      } else if (video.requestFullscreen) {
        var request = video.requestFullscreen();
        if (request && request.catch) request.catch(function () {});
      } else if (video.webkitRequestFullscreen) {
        video.webkitRequestFullscreen();
      }
    } else if (data.command === "exitFullscreen") {
      if (document.fullscreenElement && document.exitFullscreen) {
        var exit = document.exitFullscreen();
        if (exit && exit.catch) exit.catch(function () {});
      } else if (typeof video.webkitExitFullscreen === "function") {
        video.webkitExitFullscreen();
      } else if (typeof video.webkitSetPresentationMode === "function") {
        video.webkitSetPresentationMode("inline");
      }
    }
    mediaState(video, true);
  }, false);

  document.addEventListener("fullscreenchange", function () { mediaState(currentVideo(), true); }, true);
  window.addEventListener("pagehide", function () { post({ type: "clear" }); });

  window.fetch = function () {
    try {
      var request = arguments[0];
      remember(typeof request === "string" ? request : request && request.url, "fetch", false);
    } catch (_) {}
    return originalFetch.apply(this, arguments);
  };

  XMLHttpRequest.prototype.open = function (method, url) {
    try { remember(String(url || ""), "xhr", false); } catch (_) {}
    return originalXHROpen.apply(this, arguments);
  };

  try {
    var observer = new PerformanceObserver(function (list) {
      list.getEntries().forEach(function (entry) { remember(entry.name, "performance", false); });
    });
    observer.observe({ type: "resource", buffered: true });
  } catch (_) {}

  function start() {
    cleanEmbeddedPlayerChrome();
    scan(document);
    scanPerformance();
    if (frameHasDownloadableMedia()) installUI();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", start, { once: true });
  } else {
    start();
  }

  new MutationObserver(function (mutations) {
    mutations.forEach(function (mutation) { mutation.addedNodes.forEach(scan); });
    cleanEmbeddedPlayerChrome();
    if (!document.getElementById("__tonyVidCatchButton") && frameHasDownloadableMedia()) installUI();
  }).observe(document.documentElement || document, { childList: true, subtree: true });

  setInterval(function () {
    scan(document);
    scanPerformance();
    if (!button && frameHasDownloadableMedia()) installUI();
    else refreshAvailability();
  }, 2500);
})();
