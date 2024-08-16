import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="popup"
export default class extends Controller {
  static targets = [
    "popup", "grid",
    "blockStart", "blockEnd"
  ]
  start_str = "Beginning: "
  end_str = "Until: "

  show() {
    this.popupTarget.style.display = "flex"

    let intervals = event.target.value.split(" ")

    this.blockStartTarget.innerText = this.start_str + intervals[0]
    this.blockEndTarget.innerText = this.end_str + intervals[1]
  }

  hide() {
    this.popupTarget.style.display = "none"
  }
}
