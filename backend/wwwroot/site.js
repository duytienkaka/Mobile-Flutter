(function () {
  var yearNode = document.getElementById("year");
  if (yearNode) {
    yearNode.textContent = String(new Date().getFullYear());
  }

  var btn = document.getElementById("downloadApkBtn");
  if (!btn) return;

  var apkPath = "/downloads/mobile-flutter.apk";
  var apkUrl = window.location.origin + apkPath;
  var qrNode = document.getElementById("apkQrImage");
  var apkUrlTextNode = document.getElementById("apkUrlText");

  if (qrNode) {
    var encoded = encodeURIComponent(apkUrl);
    qrNode.src = "https://api.qrserver.com/v1/create-qr-code/?size=360x360&data=" + encoded;
  }

  if (apkUrlTextNode) {
    apkUrlTextNode.textContent = apkUrl;
  }

  btn.addEventListener("click", async function () {
    btn.disabled = true;
    var original = btn.textContent;
    btn.textContent = "Đang kiểm tra APK...";

    try {
      var response = await fetch(apkPath, { method: "HEAD" });
      if (response.ok) {
        window.location.href = apkPath;
        return;
      }
      alert("APK chưa được cập nhật. Vui lòng quay lại sau.");
    } catch (_) {
      alert("Không thể kết nối để tải APK. Vui lòng thử lại sau.");
    } finally {
      btn.disabled = false;
      btn.textContent = original;
    }
  });
})();
