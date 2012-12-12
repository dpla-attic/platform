// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
$(".search-fields").each(function(index, e) { if ($(e).find("input").val() != '') $(e).addClass("in"); });
console.log($(".search-fields"));