
// Hamburger menu start 
document.getElementById('hamburgler').addEventListener('click', checkNav);
window.addEventListener("keyup", function (e) {
  if (e.keyCode == 27) closeNav();
}, false);

function checkNav() {
  if (document.body.classList.contains('hamburgler-active')) {
    closeNav();
  } else {
    openNav();
  }
}

function closeNav() {
  document.body.classList.remove('hamburgler-active');
}

function openNav() {
  document.body.classList.add('hamburgler-active');
}

// Hamburger menu end



// show the sub menu after 800 px from top
$(document).ready(function (){
  $('.subnav').hide();
  $(document).scroll(function (){
    var y_top_screen = $(this).scrollTop();

    var win_height = $(window).height()
    var win_scrollTop = $(window).scrollTop()
    var scroll_bottom = win_scrollTop + win_height;
    var footer = $('.container-footer');
    var footer_offset_top = footer.offset().top
    var footer_top = scroll_bottom - footer_offset_top;
    var is_on_screen = footer_top > 0

    if (y_top_screen > 800 && !is_on_screen) {
      $('.subnav').fadeIn();
    } else {
      $('.subnav').fadeOut();
    }
  });
});

//sub navigations
var gPrevToc = null;
function changeMenu(found) {
  if (found.length == 0) {
    return;
  }
  //remove highlight when switch the submenu
  $("ul.submenu li a.active").removeClass("active");

  if (found.hasClass("toc")) {
    var toc = found;
    // only update if PrevToc is different than new toc
    if (gPrevToc == null || toc.text() != gPrevToc.text()) {
      $("a.toc.active").removeClass("active");
      var submenu = toc.next();
      if (gPrevToc != null) {
        gPrevToc.next().hide();
        gPrevToc = toc;
      }
      else {
        gPrevToc = toc;
      }
      toc.addClass("active");
      submenu.fadeIn(500);
      //console.log("f = "+found.text() + " = " + found[0].tagName);
      //console.log("toc = "+toc.text() + " = " + toc[0].tagName);
      //console.log("gPrevToc = "+gPrevToc.text() + " = " + gPrevToc[0].tagName);
      //console.log("submenu = "+submenu.length);
    }
  } else {
    var toc = found.parent().parent().parent().find(".toc");
    found.addClass("active");

    // only update if PrevToc is different than new toc
    if (gPrevToc == null || toc.text() != gPrevToc.text()) {
      $("a.toc.active").removeClass("active");
      if (gPrevToc != null) {
        gPrevToc.next().hide();
        gPrevToc = toc;
      }
      else {
        gPrevToc = toc;
      }
      var submenu = found.closest(".submenu");
      toc.addClass("active");
      submenu.fadeIn(500);
      //console.log("f = "+found.text() + " = " + found[0].tagName);
      //console.log("toc = "+toc.text() + " = " + toc[0].tagName);
      //console.log("gPrevToc = "+gPrevToc.text() + " = " + gPrevToc[0].tagName);
      //console.log("submenu = "+submenu.length);
    }
  }
}

$(document).ready(function () {
  //mounse enter the project area, highlight the menu
  $("section").mouseenter(function () {
    var id = $(this).attr('id');
    var found = $("[href=#" + id + "]");
    changeMenu(found);
  });

  //when click the toc, hightlight the menu
  $(".toc,.submenu a").click(function () {
    var found = $(this);
    changeMenu(found);
  });
});


// this is for loading
//paste this code under the head tag or in a separate js file.
// Wait for window load
$(window).load(function () {
  // Animate loader off screen
  $(".se-pre-con").fadeOut("slow");;
});


// go to top code
$(function(){
  //Scroll event
  $(window).scroll(function(){
  var scrolled = $(window).scrollTop();
  if (scrolled > 200) $('.go-top').fadeIn('slow');
  if (scrolled < 200) $('.go-top').fadeOut('slow');
  });

  //Click event
  $('.go-top').click(function () {
  $("html, body").animate({ scrollTop: "0" },  500);
  });
  });
