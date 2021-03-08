import { Controller } from "stimulus"

export default class extends Controller {
  // static targets = [ "sale"w ]

  connect() {
  }

  show(event) {
    event.preventDefault();

    const uuid = event.currentTarget.getAttribute('data-uuid')
    console.log(`GET /api/sales/${uuid}`);
  }
}