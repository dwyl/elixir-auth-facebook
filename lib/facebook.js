export function facebook(fbutton, token) {
  if (fbutton) {
    (function (d, s, id) {
      var js,
        fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) {
        return;
      }
      js = d.createElement(s);
      js.id = id;
      js.src = "https://connect.facebook.net/en_US/sdk.js";
      fjs.parentNode.insertBefore(js, fjs);
    })(document, "script", "facebook-jssdk");

    window.fbAsyncInit = function () {
      FB.init({
        appId: `${window.app_id}`,
        cookie: true,
        xfbml: false,
        version: "v15.0",
      });
      fbutton.addEventListener("click", () => {
        console.log("click");
        FB.getLoginStatus(function (response) {
          statusChangeCallback(response);
        });
      });
    };

    function statusChangeCallback(response) {
      if (response.status === "connected") {
        testAPI();
      } else {
        startDialog();
      }
    }

    function testAPI() {
      FB.api("/me?fields=id,email,name,picture", async function (response) {
        return fetch("/auth/fbsdk", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": token,
          },
          body: JSON.stringify(response),
        }).catch((err) => console.log(err));
      });
    }

    function startDialog() {
      FB.login(
        function (response) {
          if (response.status === "connected") {
            testAPI();
          }
        },
        { scope: "public_profile,email" }
      );
    }
  }
}
