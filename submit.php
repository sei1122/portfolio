<?PHP

	$to = "seikoigi@gmail.com"; #set addres to send for to 
	$subject = "Message from Portfolio"; #set the subject line 
	$headers = "From: FormMailer@seikoigi.com". "\r\n" .			
				"Reply-To: FormMailer@seikoigi.com" . "\r\n"; #set the from address 
	$forward = 1; # redirect? 1 : yes || 0 : no 
	$location = "thanks.html"; #set page to redirect to, if 1 is above 

	date_default_timezone_set('America/Los_Angeles');
	$date = date("Y/m/d"); 
	$time = date("h:i:sa"); 

	$msg = "Message from Portfolio site.  Submitted on $date at $time.\n\n"; 
	     
	foreach ($_POST as $key => $value) { 
	    $msg .= ucfirst ($key) ." : ". $value . "\n"; 
	} 
	mail($to, $subject, $msg, $headers, " -fFormMailer@seikoigi.com"); 
	if ($forward == 1) { 
	    echo ('<script type="text/javascript">location.href = "' . $location . '"</script>');  
	} 
	else { 
	    echo ("Thank you for submitting our form. I will get back to you as soon as possible."); 
	} 

?>
