import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    if (event.key !== "Enter" || (!event.metaKey && !event.ctrlKey)) return

    event.preventDefault()
    this.element.form.requestSubmit()
  }
}
