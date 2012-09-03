editInstanceStyleDialog = $( "#editInstanceStyleDialog" ).dialog
	autoOpen: false
	height: 300
	width: 350
	modal: true
	buttons:
		"OK": =>
			@strokeDasharray = outlinePattern
			alert(@strokeDasharray)
		Cancel: =>
			$( this ).dialog( "close" );
	close: =>
		allFields.val( "" ).removeClass( "ui-state-error" );
