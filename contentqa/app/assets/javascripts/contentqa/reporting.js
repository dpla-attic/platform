// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

// index page
$(".sortable").tablesorter({
    headers: {
        2: {sorter: false},
        3: {sorter: false},
        4: {sorter: false},
        5: {sorter: false},
        6: {sorter: false},
        7: {sorter: false},
        8: {sorter: false}
    }
});

// errors page
$(".error_table:first").show();

$(".error_link").bind("click", function() {
    $(".error_table").hide();
    $("#" + $(this).attr("id") + "_table").show();
});

// provider/global page
$('#check_all').on("click", function() {
    var checked = this.checked;
    $('input[name="reports[]"]:enabled').map(function() {
        $(this).prop("checked", checked);
    })
});

if ($('.running').length) {
    setInterval(function() {
        var ingest_id = $('#id').val();
        var provider = $('#provider').val();
        var url;
        if (provider == "global") {
            url = "/qa/reporting/global"
        }
        else {
            url = "/qa/reporting/provider"
        }
        $.ajax({
            url: url,
            data: {id: ingest_id}
        });
    }, 10000);
}
