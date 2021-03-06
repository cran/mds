#' Assess Analyses Definitions
#'
#' Define analyses based on an MD-PMS device-event data frame and, optionally,
#' an MD-PMS exposure data frame. See Details for how to use.
#'
#' @param deviceevents A device-events object of class \code{mds_de}, created by
#' a call to \code{deviceevent()}.
#'
#' @param device_level String value indicating the source device variable name
#' to analyze by. If \code{exposure} is specified, \code{exposure} data will be
#' matched by \code{device_level}. If a hierarchy of 2 or more are present,
#' see Details for important information.
#'
#' Example: If the \code{deviceevents} variable column is \code{device_1} where
#' the source variable name for \code{device_1} is \code{'Device Code'}, specify
#' \code{device_level='Device Code'}.
#'
#' @param event_level String value indicating the source event variable name to
#' analyze by. Note that \code{event_level} is not matched to \code{exposure}.
#' If a hierarchy of 2 or more are present, see Details for important
#' information.
#'
#' Example: If the \code{deviceevents} variable column is \code{event_1} where
#' the source variable name for \code{event_1} is \code{'Event Code'}, specify
#' \code{event_level='Event Code'}.
#'
#' Default: \code{NULL} will not analyze by event.
#'
#' @param exposure Optional exposure object of class \code{mds_e}. See details
#' for how exposure analyses definitions are handled.
#'
#' Default: \code{NULL} will not consider inclusion of exposure.
#'
#' @param date_level String value for the primary date unit to analyze by. Can
#' be either \code{'months'} or \code{'days'}.
#'
#' Default: \code{'months'}
#'
#' @param date_level_n Numeric value indicating the number of \code{date_level}s
#' to analyze by.
#'
#' Example: \code{date_level='months'} and \code{date_level_n=3} indicates
#' analysis on a quarterly level.
#'
#' Default: \code{1}
#'
#' @param covariates Character vector specifying names of covariates to also
#' define analyses for. Acceptable names are covariate variables specified
#' in \code{deviceevents}. If the covariate is a factor, additional subgroup
#' analyses will be defined at each level of the factor. \code{"_none_"}
#' specifies no covariates, while \code{"_all_"} are all covariates specified in
#' \code{deviceevents}. See details for more.
#'
#' Example: \code{c("Country", "Region")}
#'
#' Default: \code{"_none_"} specifies no covariates.
#'
#' @param times_to_calc Integer value indicating the number of date units
#' counting backwards from the latest date to define analyses for. If
#' \code{prior} is specified, \code{times_to_calc} will be ignored.
#'
#' Example 1: \code{times_to_calc=12} with \code{date_level="months"} and
#' \code{date_level_n=1} defines analyses for the last year by month.
#'
#' Example 2: \code{times_to_calc=8} with \code{date_level="months"} and
#' \code{date_level_n=3} defines analyses for the 2 years by quarter.
#'
#' Default: \code{NULL} will define analyses across all available time.
#'
#' @param invivo Logical value indicating whether to include \code{time_invivo}
#' from \code{deviceevents} in the analysis definition. See details for more.
#'
#' Default: \code{FALSE} will not include \code{time_invivo} in the analysis
#' definition.
#'
#' @param prior Future placeholder, currently not used.
#'
#' @return A list of defined analyses of class \code{mds_das}.
#' Each list item, indexed by a numeric key, defines a set of analyses for a
#' unique combination of device, event, and covariate level. Each list item is
#' of the class \code{mds_da}.
#' Attributes of class \code{mds_das} are as follows:
#' \describe{
#'   \item{date_level}{Defined value for \code{date_level}}
#'   \item{date_level_n}{Defined value for \code{date_level_n}}
#'   \item{device_level}{Defined value for \code{device_level}}
#'   \item{event_level}{Defined value for \code{event_level}}
#'   \item{times_to_calc}{Defined value for \code{times_to_calc}}
#'   \item{prior_used}{Boolean for whether \code{prior} was specified.}
#'   \item{timestamp}{System time when the analyses were defined.}
#' }
#'
#' @details \code{define_analyses()} is a prerequisite to calling
#' \code{time_series()}. This function enumerates all possible analyses based
#' on input device-event (\code{deviceevent()}) and, optionally,
#' exposure (\code{exposure()}) data frames. An analysis is defined as a set of
#' instructions specifying at minimum the device level, event level, the date
#' range of analysis, and the date unit. Additional instructions include the
#' covariate level, time in-vivo status, and exposure levels.
#'
#' By separating the analysis enumeration (\code{define_analyses()}) from the
#' generation of the time series (\code{time_series()}), the user may rerun
#' the analyses on different datasets and/or filter the analyses to only those
#' of interest.
#'
#' The analyses definitions will always include rollup levels for each
#' of \code{device_level}, \code{event_level} (if specified), and
#' \code{covariates}. Rollups are analyses at all device, event, and/or
#' covariate levels. These rollup analyses will be indicated by the keyword
#' 'All' in the analysis definition.
#'
#' When a hierarchy of 2 or more variables for either \code{device_level} or
#' \code{event_level} are present in \code{deviceevents},
#' \code{define_analyses()} will enforce the 1-level-up parent level ONLY.
#' Additional higher parent levels are not currently enforced, thus the user is
#' advised to uniquely name the 1-level-up parent level. The parent level
#' DOES NOT ROLLUP currently because the parent level is intended to separate
#' disparate data and devices. This may change in the future.
#'
#' If \code{exposure} is specified, any available \code{match_levels} will be
#' used to calculate the appropriate timeframe for analyses. The exception are
#' the special rollup analyses (see prior paragraph).
#'
#' When \code{covariates} are specified, a special rollup analysis definition
#' will always be defined that does not consider the covariates at all. This
#' analysis can be identified by \code{covariate='Data'} and
#' \code{covariate_level='All'} in the output \code{mds_da} object.
#'
#' When \code{covariates} are specified and there is no variation in the
#' distribution of covariate values (e.g. all males, all 10, all missing) in the
#' device- and event-specific dataset, these specific analyses will be dropped.
#'
#' When factor \code{covariates} are specified, covariate-level analyses may be
#' defined two ways: 1) detect an overall covariate level effect,
#' also known as a 3-dimensional analysis, and 2) subset the data by each
#' level of the covariate, also known as a subgroup analysis. 1) will be
#' denoted as \code{covariate_level='All'} in the output \code{mds_da} object,
#' while 2) will specify the factor level in \code{covariate_level}.
#'
#' If \code{invivo=TRUE}, \code{define_analyses()} will first verify if data
#' exists in the \code{time_invivo} variable for the given \code{device_level},
#' \code{event_level}, and, if applicable, \code{covariates} level. If no data
#' exists, \code{invivo} will be implicitly assigned to \code{FALSE}.
#'
#' @examples
#' # Device-Events
#' de <- deviceevent(
#'   data_frame=maude,
#'   time="date_received",
#'   device_hierarchy=c("device_name", "device_class"),
#'   event_hierarchy=c("event_type", "medical_specialty_description"),
#'   key="report_number",
#'   covariates=c("region"),
#'   descriptors="_all_")
#' # Exposures
#' ex <- exposure(
#'   data_frame=sales,
#'   time="sales_month",
#'   device_hierarchy="device_name",
#'   match_levels="region",
#'   count="sales_volume")
#' # Defined Analyses - Simple example
#' da <- define_analyses(de, "device_name")
#' # Defined Analyses - Simple example with a quarterly analysis
#' da <- define_analyses(de, "device_name", date_level_n=3)
#' # Defined Analyses - Example with event type, exposures, and covariates
#' da <- define_analyses(de, "device_name", "event_type", ex, covariates="region")
#'
#' @export
define_analyses <- function(
  deviceevents,
  device_level,
  event_level=NULL,
  exposure=NULL,
  date_level="months",
  date_level_n=1,
  covariates="_none_",
  times_to_calc=NULL,
  invivo=FALSE,
  prior=NULL
){
  # Current possibles
  # -----------------
  # Covariates
  if (all(covariates == "_none_")){
    covariates <- NULL
  } else if (all(covariates == "_all_")){
    covariates <- names(attributes(deviceevents)$covariates)
  }

  # Check parameters
  # ----------------
  input_param_checker(deviceevents, check_class="mds_de")
  input_param_checker(exposure, check_class="mds_e")
  input_param_checker(date_level_n, check_class="numeric", max_length=1)
  input_param_checker(device_level, check_class="character",
                      check_names=char_to_df(
                        attributes(deviceevents)$device_hierarchy),
                      max_length=1)
  input_param_checker(event_level, check_class="character",
                      check_names=char_to_df(
                        attributes(deviceevents)$event_hierarchy),
                      max_length=1)
  input_param_checker(covariates, check_class="character",
                      check_names=char_to_df(
                        names(attributes(deviceevents)$covariates)))
  input_param_checker(times_to_calc, check_class="numeric", max_length=1)
  input_param_checker(invivo, check_class="logical", max_length=1)
  input_param_checker(prior, check_class=c("mds_da", "mds_das"))
  if (!is.null(times_to_calc)){
    if (times_to_calc < 1 | (times_to_calc %% 1 != 0)){
      stop("times_to_calc must be positive integer")
    }
  }

  # Filter deviceevents and exposure by times_to_calc if prior is NULL
  # ------------------------------------------------------------------
  if (is.null(prior) & !is.null(times_to_calc)){
    # Get the latest date
    if (is.null(exposure)){
      max2 <- as.Date("1900-01-01")
    } else max2 <- max(exposure$time)
    latest_date <- max(max(deviceevents$time), max2)
    latest_date <- convert_date(latest_date, date_level, date_level_n)
    # Calculate the lower cutoff date
    cutoff_date <- attributes(latest_date)$adder(latest_date, -times_to_calc)
    # Filter
    deviceevents <- deviceevents[deviceevents$time >= cutoff_date, ]
    if (!is.null(exposure)){
      exposure <- exposure[exposure$time >= cutoff_date, ]
    }
  }

  # Set analysis output & analysis index (index will become primary key)
  out <- list(); z <- 1

  # Devices - Enumerate
  # -------------------
  # Current level device variable
  dev_index <- which(attributes(deviceevents)$device_hierarchy == device_level)
  dev_lvl <- names(dev_index)
  # 1-level up hierarchy device variable
  if (length(attributes(deviceevents)$device_hierarchy) == dev_index){
    dev_1up <- dev_lvl
  } else{
    dev_1up <- names(attributes(deviceevents)$device_hierarchy)[dev_index + 1]
    dev_1up <- ifelse(length(dev_1up) == 0, dev_lvl, dev_1up)
  }
  # Calculate the rollup level for the last loop
  uniq_devs <- c(unique(as.character(deviceevents[[dev_lvl]])), "All")
  # Loop through every level of the current device variable
  i <- 1
  while (i <= length(uniq_devs)){
    devDE <- deviceevents
    # Filter for the current device
    # device is a holding variable
    if (i == length(uniq_devs)){
      devDE$device <- "All"
    } else{
      devDE <- devDE[devDE[[dev_lvl]] == uniq_devs[i], ]
      devDE$device <- devDE[[dev_lvl]]
    }
    # Loop through every level of the 1-up device variable
    if (is.na(dev_1up) | (devDE$device[1] == "All" & dev_1up == dev_lvl)){
      uniq_dev_1up <- NA
    } else uniq_dev_1up <- unique(as.character(devDE[[dev_1up]]))

    for (i1 in uniq_dev_1up){
      if (!is.na(uniq_dev_1up[1])){
        devDE1up <- devDE[devDE[[dev_1up]] == i1, ]
      } else devDE1up <- devDE

      # Events - Enumerate
      # ------------------
      # Current level event variable
      ev_index <- which(attributes(deviceevents)$event_hierarchy == event_level)
      ev_lvl <- names(ev_index)
      # 1-level up hierarchy event variable
      if (is.null(ev_lvl)){
        ev_1up <- "<>"
      } else{
        if (length(attributes(deviceevents)$event_hierarchy) == ev_index){
          ev_1up <- "<>"
        } else{
          ev_1up <- attributes(deviceevents)$event_hierarchy[ev_index + 1]
          ev_1up <- ifelse(length(ev_1up) == 0, "<>", names(ev_1up))
        }
      }
      ev_1up_lab <- ifelse(
        ev_1up == "<>",
        as.character(attributes(deviceevents)$event_hierarchy[ev_index]),
        as.character(attributes(deviceevents)$event_hierarchy[ev_index + 1]))
      # Calculate the rollup level for the last loop
      if (is.null(ev_lvl)){
        uniq_evts <- c("All")
      } else{
        uniq_evts <- c(as.character(unique(devDE1up[[ev_lvl]])), "All")
      }
      # Loop through every level of the current event variable
      j <- 1
      while (j <= length(uniq_evts)){
        devDEev <- devDE1up
        # Filter for the current event
        # event is a holding variable
        if (j == length(uniq_evts)){ # Set rollup level
          devDEev$event <- "All"
        } else{
          devDEev <- devDEev[devDEev[[ev_lvl]] == uniq_evts[j], ]
          devDEev$event <- devDEev[[ev_lvl]]
        }
        # Loop through every level of the 1-up event variable
        if (ev_1up == "<>"){
          uniq_ev_1up <- ev_1up
        } else uniq_ev_1up <- unique(as.character(devDEev[[ev_1up]]))
        for (j1 in uniq_ev_1up){
          if (j1 != "<>"){
            devDEev1up <- devDEev[devDEev[[ev_1up]] == j1, ]
          } else devDEev1up <- devDEev
          # Covariates - Enumerate
          # ----------------------
          if (is.null(covariates)){
            uniq_covs <- list("Data"="All")
          } else{
            uniq_covs <- lapply(covariates, function(x){
              if (is.factor(devDEev1up[[x]])){
                this <- c(unique(as.character(devDEev1up[[x]])), "All")
                # Identify no variance cases
                if (length(this) == 2) this <- "_novar_"
              } else if (is.numeric(devDEev1up[[x]])){
                this <- "All"
                # Identify no variance cases
                if (length(unique(devDEev1up[[x]])) == 1) this <- "_novar_"
              }
              # WARNING! If ever the upstream restriction of no NA's in the
              # covariates is removed, this will produce NA's as a unique
              # level. Subsequent handling of NAs is present but untested.
              this
            })
            names(uniq_covs) <- covariates
            uniq_covs$Data <- "All" # Set rollup level
          }

          # Save analysis instructions by each level of device, event, covariate
          # --------------------------------------------------------------------
          for (k in names(uniq_covs)){
            for (l in uniq_covs[[k]]){
              # If no variance for this covariate, skip
              skip <- F
              if (!is.na(l)){
                if (l == "_novar_") skip <- T
              }
              if (!skip){
                # Entire analysis requires:
                # 1. Data All level: covariates not considered (the rollup level as
                #    the last loop)
                # Each covariate requires:
                # 2. Marginal level: analyze for effects of the covariate as a whole
                # 3. Nominal level (optional): subset by each nominal/binary type
                #    variable
                if (is.na(l) & is.factor(devDEev1up[[k]])){ # NA Nominal level
                  devCO <- devDEev1up[is.na(devDEev1up[[k]]), ]
                } else if (l %in% c("All")){ # Marginal/Data All level & numeric
                  devCO <- devDEev1up
                } else if (is.factor(devDEev1up[[k]])){ # Nominal level
                  devCO <- devDEev1up[devDEev1up[[k]] == l, ]
                } else stop("Unknown covariate filtering specification")

                # If only 1 row of data remains, skip
                if (nrow(devCO) > 1){
                  # Verify time in-vivo variable has variance
                  vivovar <- F
                  if (!is.null(attributes(deviceevents)$time_invivo)){
                    if (invivo & length(unique(devCO$time_invivo)) > 1){
                      vivovar <- T
                    }
                  }

                  # Assemble output starting with non-exposure data
                  # -----------------------------------------------
                  # Establish date range
                  dt_range <- convert_date(range(devCO$time, na.rm=T),
                                           date_level, date_level_n)
                  names(dt_range) <- c("start", "end")
                  # Build list of instructions
                  this <- list(
                    z,
                    device_level,
                    stats::setNames(as.character(devCO$device[1]), dev_lvl),
                    attributes(deviceevents)$device_hierarchy[[dev_1up]],
                    stats::setNames(i1, dev_1up),
                    ifelse(is.null(ev_lvl),
                           attributes(deviceevents)$event_hierarchy[[1]],
                           event_level),
                    stats::setNames(devCO$event[1], ifelse(
                      is.null(ev_lvl),
                      names(attributes(deviceevents)$event_hierarchy)[1],
                      ev_lvl)),
                    ev_1up_lab,
                    stats::setNames(
                      ifelse(j1 != "<>", j1, NA),
                      ifelse(ev_1up == "<>",
                             names(attributes(
                               deviceevents)$event_hierarchy)[ev_index],
                             ev_1up)),
                    k, l,
                    vivovar,
                    attributes(dt_range)$adder,
                    dt_range)
                  names(this) <- c("id",
                                   "device_level_source", "device_level",
                                   "device_1up_source", "device_1up",
                                   "event_level_source", "event_level",
                                   "event_1up_source", "event_1up",
                                   "covariate", "covariate_level",
                                   "invivo",
                                   "date_adder",
                                   "date_range_de")

                  # Exposure Case
                  # -------------
                  if (is.null(exposure)){
                    thes <- data.frame()
                  } else thes <- exposure
                  dev_level_e <- dev_1up_e <- cov_level_e <- stats::setNames(NA,
                                                                             NA)
                  # Filter by current device level
                  if (nrow(thes) > 0 &
                      this$device_level_source %in%
                      attributes(exposure)$device_hierarchy){
                    dev_label <- names(which(attributes(
                      exposure)$device_hierarchy == this$device_level_source))
                    dev_level_e <- stats::setNames(
                      as.character(this$device_level), dev_label)
                    if (dev_level_e != "All"){
                      thes <- thes[thes[[names(dev_level_e)]] == dev_level_e, ]
                      if (nrow(thes) == 0){
                        dev_level_e <- stats::setNames(NA, dev_label)
                      }
                    }
                  }
                  this$exp_device_level <- dev_level_e
                  # Filter by 1-up device level
                  if (nrow(thes) > 0 &
                      this$device_1up_source %in%
                      attributes(exposure)$device_hierarchy){
                    dev_label <- names(which(attributes(
                      exposure)$device_hierarchy == this$device_1up_source))
                    dev_1up_e <- stats::setNames(as.character(this$device_1up),
                                                 dev_label)
                    if (!is.na(dev_1up_e)){
                      if (dev_1up_e != "All"){
                        thes <- thes[thes[[names(dev_1up_e)]] == dev_1up_e, ]
                        if (nrow(thes) == 0){
                          dev_1up_e <- stats::setNames(NA, dev_label)
                        }
                      }
                    }
                  }
                  this$exp_device_1up <- dev_1up_e
                  # Filter by event
                  # NOT IMPLEMENTED <A possible future feature, if requested.>
                  # Filter for the current covariate level
                  if (nrow(thes) > 0 &
                      this$covariate %in% attributes(exposure)$match_levels){
                    cov_level_e <- stats::setNames(l, k)
                    if (is.na(l)){ # covariate level is NA case
                      thes <- thes[is.na(thes[[k]]), ]
                    } else if (l != "All"){ # covariate level is nominal, non-NA
                      thes <- thes[as.character(thes[[k]]) == l, ]
                    } # marginal & Data All levels implied by not filtering
                    if (nrow(thes) > 0) this$exp_covariate_level <- cov_level_e
                  }
                  # Establish exposure date range, if exposure data exists
                  if (nrow(thes) > 0){
                    dt_range <- convert_date(range(thes$time, na.rm=T),
                                             date_level, date_level_n)
                    names(dt_range) <- c("start", "end")
                    this$date_range_exposure <- dt_range
                  } else this$date_range_exposure <- c(as.Date(NA), as.Date(NA))
                  # Establish date range if exposure is to be used in analysis
                  # If exposure is not used, date range is the same as
                  # device-events
                  dt_range <- c(
                    max(c(this$date_range_de[1], this$date_range_exposure[1]),
                        na.rm=T),
                    min(c(this$date_range_de[2], this$date_range_exposure[2]),
                        na.rm=T))
                  dt_range <- convert_date(dt_range, date_level, date_level_n)
                  names(dt_range) <- c("start", "end")
                  this$date_range_de_exp <- dt_range

                  # Finally, save the analysis
                  # --------------------------
                  class(this) <- append(class(this), "mds_da")
                  out[[z]] <- this
                  z <- z + 1
                }
              }
            }
          }
        }
        j <- j + 1
      }
    }
    i <- i + 1
  }

  # Save the output class
  # ---------------------
  out <- structure(out,
                   date_level=date_level,
                   date_level_n=date_level_n,
                   device_level=device_level,
                   event_level=event_level,
                   times_to_calc=times_to_calc,
                   prior_used=!is.null(prior),
                   timestamp=Sys.time())
  class(out) <- append(class(out), "mds_das")

  return(out)
}


#' Create Data Frame from Analyses Definitions
#'
#' Returns a data frame summarizing all defined analyses from the
#' \code{mds_das} object.
#'
#' @param inlist Object of class \code{mds_das}
#' @return A data frame with each row representing an analysis.
#' @export
define_analyses_dataframe <- function(
  inlist
){
  input_param_checker(inlist, check_class="mds_das")
  all <- data.frame()
  for(j in 1:length(inlist)){
    x <- inlist[[j]]
    for(i in 1:length(x)){
      date_flag <- func_flag <- F
      if ("factor" %in% class(x[[i]])){
        x[[i]] <- as.character(x[[i]])
      } else if ("Date" %in% class(x[[i]])){
        date_flag <- T
      } else if ("function" %in% class(x[[i]])){
        func_flag <- T
      }
      if (length(x[[i]]) > 1){
        this <- data.frame(t(data.frame(x[i])), stringsAsFactors=F)
        if (is.null(colnames(this))){
          coln <- rep("", length(this))
        } else coln <- colnames(this)
        colnames(this) <- paste0(rownames(this), "_", coln)
      } else if (length(x[[i]]) == 0){
        x[[i]] <- NA
      } else if (func_flag){
        x[[i]] <- NA
      } else{
        this <- as.data.frame(x[i], stringsAsFactors=F, row.names="")
      }
      if (date_flag){
        this <- do.call("cbind.data.frame", lapply(this, as.Date))
      }
      if (all(!is.na(x[[i]]))){
        if (exists("out")){
          out <- cbind.data.frame(out, this, stringsAsFactors=T)
        } else{
          # out <- cbind.data.frame(id=j, this)
          out <- this
        }
      }
    }
    # If column names are not equal, use the more descriptive set of names
    ncall <- nchar(paste(names(all), collapse=""))
    ncout <- nchar(paste(names(out), collapse=""))

    if (nrow(all) > 0){
      if (ncall > ncout){
        # browser()#########################

        out[setdiff(names(all), names(out))] <- NA
        # names(out) <- names(all)
      } else if (ncout > ncall){
        all[setdiff(names(out), names(all))] <- NA

        # names(all) <- names(out)
      }
    }
    # Combine
    all <- rbind.data.frame(all, out, stringsAsFactors=F)
    rm(out)
  }
  rownames(all) <- c()
  return(all)
}

#' Summarize a Collection of MD-PMS Defined Analyses
#' Prints basic counts and date ranges by various analysis factors as defined in
#' the original \code{define_analyses()} call.
#' @param object A MD-PMS Defined Analyses object of class \code{mds_das}
#' @param ... Additional arguments affecting the summary produced
#' @return List of analyses counts and date ranges.
#' @export
summary.mds_das <- function(
  object, ...
){
  input_param_checker(object, check_class="mds_das")
  df <- define_analyses_dataframe(object)
  counts <- stats::setNames(
    c(length(object),
      ifelse(is.null(df$date_range_exposure_start), 0,
             nrow(df[!is.na(df$date_range_exposure_start), ])),
      length(unique(df$device_level)),
      length(unique(df$event_level)),
      length(unique(df$covariate))),
    c('Total Analyses',
      'Analyses with Exposure',
      'Device Levels',
      'Event Levels',
      'Covariates'))
  date_ranges <- data.frame(
    'Data'=c('Device-Event', 'Exposure', 'Both'),
    'Start'=c(fNA(df$date_range_de_start, min),
              ifelse_cp(is.null(df$date_range_exposure_start), NA,
                        fNA(df$date_range_exposure_start, min)),
              fNA(df$date_range_de_exp_start, min)),
    'End'=c(fNA(df$date_range_de_end, max),
            ifelse_cp(is.null(df$date_range_exposure_end), NA,
                      fNA(df$date_range_exposure_end, max)),
            fNA(df$date_range_de_exp_end, max)), stringsAsFactors=T)
  list('Analyses Timestamp'=attributes(object)$timestamp,
       'Analyses Counts'=counts,
       'Date Ranges'=date_ranges)
}
