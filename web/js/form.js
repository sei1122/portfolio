var ValidateEmail = function() {
    var name = $('#name').val();
    var email = $('#email').val();
    var subject = $('#subject').val();
    var message = $('#message').val();
    var error = false;

    // clear out old error messages. 
    $('.name-error').html("");
    $('.email-error').html("");
    $('.subject-error').html("");
    $('.message-error').html("");


    // Add new error messages if needed. 
    if (name === "") {
        $('.name-error').html("Please enter your name");
        error = true;
    };

    if (email === "") {
        $('.email-error').html("Please enter your email");
        error = true;
    };

    if (subject === "") {
        $('.subject-error').html("Please enter your subject");
        error = true;
    };

    if (message === "") {
        $('.message-error').html("Please enter your message");
        error = true;
    };

    // check to see if I want to send the email or not. 
    if(error)
    {
        return false; // don't send email      
    }

    return true; // send email
};
