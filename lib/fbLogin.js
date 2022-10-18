export const fbLoginHook = {
  mounted() {
    const token = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content");
    const fbutton = document.getElementById("fbhook");

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
          appId: 366589421180047,
          cookie: true,
          xfbml: false,
          version: "v15.0",
        });

        fbutton.addEventListener("click", () => {
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
          return fetch("/auth/sdk", {
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
  },
};
