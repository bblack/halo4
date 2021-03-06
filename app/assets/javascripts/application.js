// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

Application = {
  updateChart: function(chart, url, data) {
    $.each(data, function(k,v){
      $(chart.container).parent().parent().find('.chart_options').find('#' + k).val(v);
    });

    chart.showLoading();

    while (chart.series.length > 0) {
      chart.series[0].remove(false);
    }

    $.ajax({
      url: url,
      data: data,
      success: function(d) {
        $.each(d, function(i,s){
          chart.addSeries(s);
        });
        chart.hideLoading();
      }
    });
  },

  fragToObj: function() {
    var fragString = window.location.hash.replace(/^#/, '');
    return Application.paramToObj(fragString);
  },

  paramToObj: function(s) {
    if (s == "") {
      return {};
    }
    var pairStrings = s.split('&');
    ret = {};
    $.each(pairStrings, function(i,e){
      ret[e.split('=')[0]] = e.split('=')[1];
    });
    return ret;
  },

  chartOpts: function(opts) {
    return $.extend(true, 
      {
        chart: {
          borderRadius: 0,
          borderColor: '#c0c0c0',
          borderWidth: 1,
          zoomType: 'x'
        },
        credits: {
          enabled: false
        },
        loading: {
          style: {
            position: 'absolute',
            backgroundColor: 'white',
            backgroundImage: "url('/assets/chart-loading.gif')",
            backgroundPosition: "center center",
            backgroundRepeat: "no-repeat",
            opacity: 0.5,
            textAlign: 'center'
          }
        },
        plotOptions: {
          line: {
            lineWidth: 2,
            shadow: false,
            marker: {
              enabled: false
            }
          },
          series: {
            marker: {
              states: {
                hover: {
                  enabled: false
                }
              }
            }
          }
        },
        tooltip: {
          formatter: function() { return "<b>" + this.series.name + "</b><br/>" + new Date(this.x).toString() + '<br/>' + this.y.toString(); }
        },
        xAxis: {
          type: 'datetime'
        },
        yAxis: [
          {
            title: {
              text: null,
              style: {
                color: '#4572a7'
              }
            },
            labels: {
              style: {
                color: '#4572a7'
              }
            }
          },
          {
            title: {
              text: null,
              style: {
                color: '#aa4643'
              }
            },
            labels: {
              style: {
                color: '#aa4643'
              }
            },
            opposite: true
          }
        ],
      },
      opts);
  }
};