var highlighted_element = null;
var last_hash = null;
function highlight_element(){
	let hash = document.location.hash
	if(hash != null){
		if(last_hash == hash) return;
		if(highlighted_element != null){
			highlighted_element.className=highlighted_element.className.replace(' jumped_to','')
			highlighted_element=null
		}
		last_hash = hash
		highlighted_element = document.getElementById(hash.substring(1))
		console.log(highlighted_element)
		if(highlighted_element != null){
			highlighted_element.className+=" jumped_to"
		}
	}
}
onclick = ()=>{setTimeout(highlight_element,200)}
setTimeout(highlight_element,500)