import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-visibility"
export default class extends Controller {
  static targets = ["input", "icon"];

  toggle() {
    const hidden = this.inputTarget.type === "password";

    this.inputTarget.type = hidden ? "text" : "password";
    this.iconTarget.classList.toggle("bi-eye", !hidden);
    this.iconTarget.classList.toggle("bi-eye-slash", hidden);
  }
}
