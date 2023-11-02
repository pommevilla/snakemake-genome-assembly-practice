# ---------------------------
# Rules related to reporting and visualizing assembly metrics
# Author: Paul Villanueva (github.com/pommevilla)
# ---------------------------

rule metric_plots:
    input:
    output:
    conda:
        "../envs/r-tidy.yml"
    log:
        "logs/metric_plots.log"
