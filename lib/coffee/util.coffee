window._d = window.d = console?.log.bind(console) ? ->

d3.selection.prototype.moveToFront = -> this.each -> this.parentNode.appendChild(this)
d3.selection.prototype.moveToBack = -> this.each -> this.parentNode.insertBefore this, this.parentNode.firstChild

# Returns the number of milliseconds elapsed since either the browser navigationStart event or 
# the UNIX epoch, depending on availability.
# Where the browser supports 'performance' we use that as it is more accurate (microsoeconds
# will be returned in the fractional part) and more reliable as it does not rely on the system time. 
# Where 'performance' is not available, we will fall back to Date().getTime().
window.performance = window.performance || { }
window.performance.now = 
	performance.now    	      ||
	performance.webkitNow     ||
	performance.msNow         ||
	performance.oNow          ||
	performance.mozNow        ||
	Date.now
	 
