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
          formatter: function() { return new Date(this.x).toString() + '<br/>' + this.y.toString(); }
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