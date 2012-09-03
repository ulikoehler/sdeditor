jQuery.expr[':'].focus = function( elem ) {
  return elem === document.activeElement && ( elem.type || elem.href );
};

function unfocus() {
	focusedElem = document.activeElement
	if(focusedElem && ( focusedElem.type || focusedElem.href )) {
		focusedElem.blur()
	}
}