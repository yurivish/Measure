window._d = window.d = console?.log.bind(console) ? ->

d3.selection.prototype.moveToFront = -> this.each -> this.parentNode.appendChild(this)
d3.selection.prototype.moveToBack = -> this.each -> this.parentNode.insertBefore this, this.parentNode.firstChild
