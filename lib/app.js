// ...........

import { facebook } from "./facebook";
const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");

// ..........

const fbutton = document.getElementById("fbhook");
if (fbutton) facebook(fbutton, csrfToken);
