# WHO_guideline_2024_indicators

# CHECKS
# Underweight prevalence does not correspond to Anthro Analyser
# cORRECT date_meas
# Refactor set NA_real or N<30 to "-" 
# add Note - N<30
# add Note - no MUAC data collected for children under 6 m
# Add proportion WHZ only / MUAC only / WHZ + MUAC 


# Calculation of prevalence of all screening criteria for
# screening criteria included in 2024 WHO Guideline

# Clear environment
rm(list = ls())

# Host-specific setting of hostname
hostname <- Sys.info()[['nodename']]  # or Sys.info()[["nodename"]]

# Setting work directory based on host
if (hostname == "992224APL0X0061") {
  # Robert UNICEF PC
  workdir <- "C:/Users/rojohnston/UNICEF/Data and Analytics Nutrition - Analysis Space/Child Anthropometry/1- Anthropometry Analysis Script/Prepped Country Data Files/CSV"
} else if (hostname == "MY-LAPTOP") {
  # Your laptop
  workdir <- "D:/Projects/Seasonality/"
} else {
  stop("Unrecognized hostname, Set 'workdir' manually.")
}

# Set other directories
datadir <- file.path(workdir, "Data")

search_name = "Afghanistan"


# install.packages("matrixStats")
# install.packages("labelled")
# install.packages("expss")

# Load libraries
library(readr)
library(haven)
library(ggplot2)
library(labelled)
library(matrixStats)
library(expss)
library(dplyr)
library(openxlsx)

# Collect list of files with name of country included
files <- list.files(path = workdir, pattern = search_name, full.names = TRUE)
file_names <- basename(files)
print(file_names)

# NOTE read_csv - includes the indicator label names.  read_dta does not. 

# Loop over filenames 
for (file in file_names) {
    df <- read_csv(file.path(workdir, file))
    # df <- read_csv(file.path(workdir, file, locale = locale(encoding = "UTF-8")))
    # df <- read_csv(file.path(workdir, file, locale = locale(encoding = "ISO-8859-1")))  # European languages
    # df <- read_csv(file.path(workdir, file, locale = locale(encoding = "Windows-1252"))) # Older windows excel


  # if sex, height, weight and MUAC is missing, then anthro cannot be assessed
  #  drop cases with missing sex, height, weight and MUAC
  #  df <- df %>% filter(if_all(c(sex, height, weight, muac), ~ !is.na(.x)))
    
  # Data Cleaning
  
  # create sample_wgt
  df <- df %>% mutate(sample_wgt = sw)
  # summary(df$sample_wgt)
  
  df <- df %>% mutate(Region = iconv(gregion, from = "", to = "UTF-8", sub = "byte"))
  # fre(df$gregion)
  
  # Test if variables are completely missing  ?
  indicators <- c("sex", "agemons", "waz", "whz","measure", "muac","oedema")
  sapply(df[indicators], function(x) all(is.na(x)))
  
  indicators_original <- paste0(indicators, "_original")
  indicators_original <- indicators_original[indicators_original %in% names(df)]
  sapply(df[indicators_original], function(x) all(is.na(x)))
  
  # If oedema is missing, replace oedema with oedema_original
  if ("oedema_original" %in% names(df) && all(is.na(df$oedema))) {
    df$oedema <- df$oedema_original
  }
  # fre(df$oedema)

  # If MUAC is saved in CM, convert to MM
  if ("muac" %in% names(df) && any(!is.na(df$muac))) {  # if muac is present or not all missing - continue
    if (mean(df$muac, na.rm = TRUE) < 26) {
      df$muac <- df$muac * 10  # 1 cm = 10 mm
    }
  }
  
  # sev_wast		"Severely wasted child under 5 years - WHZ"
  # wast			  "Wasted child under 5 years - WHZ"
  # mean_whz		"Mean z-score for weight-for-height for children under 5 years"
  # sev_uwt	"Severely underweight child under 5 years"
  # uwt		  "Underweight child under 5 years"
  # mean_waz		"Mean weight-for-age for children under 5 years"
  # muac_110  "Infant with severe wasting by MUAC (MUAC < 110mm) " 
  # muac_115  "Child with severe wasting by MUAC (MUAC < 115mm)" 
  # muac_125  "Child with  wasting by MUAC (MUAC < 125mm)" 
  # edema 
  # not_bf "Infant not breastfed" 
  
  # Infants under 6 months of age at risk of poor growth and development 
  
  # Percentage of infant contacts with WAZ <-2 SD of WHO child growth standards
  # Percentage of infant contacts with severe wasting by WHZ (WHZ < - 3 SD of WHO child growth standards)
  # Percentage of infant contacts with severe wasting by MUAC (MUAC < 110mm)
  # Percentage of infant contacts with nutritional oedema 
  # Percentage of infant contacts with recent weight loss (not available from surveys)
  # Percentage of infant contacts with ineffective breastfeeding, feeding concerns if not breastfed
  # Percentage of infant contacts with IMCI danger signs or acute medical problems under severe classification as per IMCI (not available from surveys)
  # COMBINED AT RISK
  
  # Children from 6 to 59 months of age 
  # Percentage of 6-59M child contacts with severe wasting (WHZ < - 3 SD of WHO child growth standards)
  # Percentage of 6-59M child contacts with severe wasting by MUAC (MUAC < 115mm)
  # Percentage of 6-59M child contacts with nutritional oedema 
  # Combined SAM
  
  # Moderate Wasting at risk
  # muac_115_125
  # sev_uwt
  # mod_muac_suwt
  # muac_115_125_24m
  # sev_uwt_24m
  # mod_muac_suwt_24m
  
  # Underweight 
  df <- df %>%
    mutate(uwt =
             case_when(
               waz <  -2~ 1,
               waz >= -2 ~ 0,
               is.na(waz) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(uwt = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(uwt = "WAZ<-2SD")
  
  # Severe Underweight 
  df <- df %>%
    mutate(sev_uwt =
             case_when(
               waz <  -3 ~ 1,
               waz >= -3 ~ 0,
               is.na(waz) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(sev_uwt = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(sev_uwt = "WAZ<-3SD")
    if (!"sev_uwt" %in% names(df)) stop("Variable 'sev_uwt' does not exist in the dataset.")
  
  
  # Severe Underweight in Children < 24M 
  df <- df %>%
    mutate(sev_uwt_24m =
             case_when(
               agemons >=24 ~ NA_real_, 
               waz <  -3 ~ 1,
               waz >= -3 ~ 0,
               is.na(waz) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(sev_uwt_24m = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(sev_uwt_24m = "WAZ<-3SD in children <24M")
  
  # Wasted 
  df <- df %>%
    mutate(wast =
             case_when(
               whz < -2  ~ 1,
               whz >= -2 ~ 0,
               is.na(whz) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(wast = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(wast = "WHZ<-2SD")
  
  # Severely wasted 
  df <- df %>%
    mutate(sev_wast =
             case_when(
               whz < -3  ~ 1,
               whz >= -3 ~ 0,
               is.na(whz) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(sev_wast = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(sev_wast = "WHZ<-3SD")
    if (!"sev_wast" %in% names(df)) stop("Variable 'sev_wast' does not exist in the dataset.")
  
  # MUAC 125 
  df <- df %>%
    mutate(muac_125 =
             case_when(
               muac < 125  ~ 1,
               muac >= 125 ~ 0,
               is.na(muac) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(muac_125 = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(muac_125 = "MUAC<125mm")
  
  # MUAC 115 
  df <- df %>%
    mutate(muac_115 =
             case_when(
               muac < 115  ~ 1,
               muac >= 115 ~ 0,
               is.na(muac) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(muac_115 = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(muac_115 = "MUAC<115mm")
  
  # MUAC 110 
  df <- df %>%
    mutate(muac_110 =
             case_when(
               muac < 110 ~ 1,
               muac >= 110 ~ 0,
               is.na(muac) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(muac_110 = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(muac_110 = "MUAC<110mm")
  
  #muac_115_119
  df <- df %>%
    mutate(muac_115_119 =
             case_when(
               muac >= 115 & muac < 120 ~ 1,
               muac < 115 | muac >= 120 ~ 0,
               is.na(muac) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(muac_115_119 = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(muac_115_119 = "MUAC 115-119mm")
  
  # muac_115_119_24m - muac_115_119 in children under 24M
  df <- df %>%
    mutate(muac_115_119_24m  =
             case_when(
               agemons >=24 ~ NA_real_, 
               muac >= 115 & muac < 120 ~ 1,
               muac < 115 | muac >= 120 ~ 0,
               is.na(muac) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(muac_115_119_24m  = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(muac_115_119_24m  = "MUAC 115-119mm")
  
# mod_muac_suwt - Variable representing combined condition of 
# child under 59m who has muac_115_119 AND sev_uwt
  df <- df %>%
    mutate(
      # Check if both inputs are available in a row
      mod_muac_suwt = case_when(
        is.na(sev_uwt) | is.na(muac_115_119) ~ NA_real_,  # Either input missing
        sev_uwt == 1 & muac_115_119 == 1 ~ 1,             # Both are 1
        TRUE ~ 0                                          # Otherwise 0
      )
    ) %>%
    set_value_labels(mod_muac_suwt = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(mod_muac_suwt = "MUAC 115-119 & Severe UWT in children under 59M")
  
# mod_muac_suwt_24m - Variable representing combined condition of 
# child under 24m who has muac_115_119 AND sev_uwt
  df <- df %>%
    mutate(
      # Check if both inputs are available in a row
      mod_muac_suwt_24m = case_when(
        is.na(sev_uwt_24m) | is.na(muac_115_119_24m) ~ NA_real_,  # Either input missing
        sev_uwt_24m == 1 & muac_115_119_24m == 1 ~ 1,             # Both are 1
        TRUE ~ 0                                                  # Otherwise 0
      )
   ) %>%
   set_value_labels(mod_muac_suwt_24m = c("Yes" = 1, "No" = 0)) %>%
   set_variable_labels(mod_muac_suwt_24m = "MUAC 115-119 & Severe UWT in children under 24M")
 
  #  Oedema
  # if oedema is not recoded, check oedema_original
  df <- df %>%
    mutate(oedema =
             case_when(
               oedema == "Oui" ~ 1,
               oedema == "n" ~ 0,
               is.na(oedema) ~ NA_real_  # handle missing values
             )) %>%
    set_value_labels(oedema = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(oedema = "bilateral oedema")
  
  # At Risk Combined
  df <- df %>%
    mutate(
      valid_inputs = rowSums(!is.na(across(c(uwt, sev_wast, muac_110, oedema)))),
      at_risk = case_when(
        valid_inputs == 0 ~ NA_real_,
        rowSums(across(c(uwt, sev_wast, muac_110, oedema)) == 1, na.rm = TRUE) > 0 ~ 1,
        TRUE ~ 0
      )
    ) %>%
    set_value_labels(at_risk = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(at_risk = "At Risk Combined")
  
  # Severe Acute Malnutrition 
  df <- df %>%
    mutate(
      valid_inputs = rowSums(!is.na(across(c(sev_wast, muac_115, oedema)))),
      sam = case_when(
        valid_inputs == 0 ~ NA_real_,
        rowSums(across(c(sev_wast, muac_115, oedema)) == 1, na.rm = TRUE) > 0 ~ 1,
        TRUE ~ 0
      )
    ) %>%
    set_value_labels(sam = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(sam = "SAM Combined")
  
  # Global Acute Malnutrition 
  df <- df %>%
    mutate(
      valid_inputs = rowSums(!is.na(across(c(wast, muac_125, oedema)))),
      gam = case_when(
        valid_inputs == 0 ~ NA_real_,
        rowSums(across(c(wast, muac_125, oedema)) == 1, na.rm = TRUE) > 0 ~ 1,
        TRUE ~ 0
      )
    ) %>%
    set_value_labels(gam = c("Yes" = 1, "No" = 0)) %>%
    set_variable_labels(gam = "GAM Combined")
  
  df <- df %>%
    mutate(blank = NA) %>%
    set_variable_labels(blank = "-")
  
  # View valid N of all indicators
  indicators <- c("sev_wast", "muac_115", "oedema", "sam", "wast", "muac_125", "gam")
  
  df %>%
    group_by(Region) %>%
    summarise(
      across(all_of(indicators), ~ sum(!is.na(.)), .names = "{.col}_N"),
      .groups = "drop"
    )
  total_row <- df %>%
    summarise(
      across(all_of(indicators), ~ sum(!is.na(.)), .names = "{.col}_N")
    ) %>%
    mutate(Region = "Total") %>%
    select(Region, everything())
  
  # Combine
  valid_n_table <- bind_rows(
    df %>%
      group_by(Region) %>%
      summarise(
        across(all_of(indicators), ~ sum(!is.na(.)), .names = "{.col}_N"),
        .groups = "drop"
      ),
    total_row
  )
  # View(valid_n_table)
  
  
  # summarise function (used in tables)
  summarise_prev_table <- function(data) {
    data %>%
      filter(!is.na(sample_wgt)) %>%
      summarise(across(
        all_of(indicators),
        list(
          `%` = ~ round(weighted.mean(.x, sample_wgt, na.rm = TRUE) * 100, 1),
          N   = ~ sum(!is.na(.x))
        ),
        .names = "{.col} ({.fn})"
      ))
  }
  
  replace_names_with_labels <- function(df_table, reference_df, indicators) {
    label_lookup <- sapply(indicators, function(x) var_lab(reference_df[[x]]), USE.NAMES = TRUE)
    names(df_table) <- sapply(names(df_table), function(name) {
      if (name == "gregion") return(name)
      match <- regexec("^(.+?)\\s*(\\(.*\\))$", name)
      parts <- regmatches(name, match)[[1]]
      if (length(parts) == 3) {
        var <- parts[2]
        suffix <- parts[3]
        label <- label_lookup[[var]]
        if (is.null(label) || label == "") label <- var
        return(paste0(label, " ", suffix))
      } else {
        return(name)
      }
    })
    df_table
  }
  
  # **************************************************************************************************
  # * Anthropometric indicators for children under age 6 months
  # **************************************************************************************************
  
  df_0_5m <- df %>% filter(agemons >=0 & agemons < 6)
  
  # AT RISK TABLE
  # WHO Guideline 2024 - Indicators for at risk and acute malnutrition
  table_name <- "at_risk_0_5m"
  df_name <- "df_0_5m"
  indicators <- c("sev_wast", "muac_110",  "oedema", "uwt", "at_risk")
  
  main_table <- get(df_name) %>%
    group_by(Region) %>%
    summarise_prev_table()
  
  total_row <- summarise_prev_table(get(df_name)) %>%
    mutate(Region = "Total") %>%
    select(Region, everything())
  
  full_table <- bind_rows(main_table, total_row)
  
  # Suppress % if N < 30
  for (var in indicators) {
    pct_col <- paste0(var, " (%)")
    n_col   <- paste0(var, " (N)")
    
    if (pct_col %in% names(full_table) && n_col %in% names(full_table)) {
      mask <- is.na(full_table[[n_col]]) | full_table[[n_col]] < 30
      if (any(mask)) {
        full_table[[pct_col]] <- as.character(full_table[[pct_col]])
        full_table[[pct_col]][mask] <- " - "
      }
    }
  }
  full_table <- replace_names_with_labels(full_table, get(df_name), indicators)
  assign(table_name, full_table)
  # View(get(table_name))
  
  # **************************************************************************************************
  # * Anthropometric indicators for children from 6- 59 months
  # **************************************************************************************************
  
  df_6_59m <- df %>% filter(agemons > 5 & agemons < 60)
  
  # SAM TABLE
  table_name <- "sam_6_59m"
  df_name <- "df_6_59m"
  indicators <- c("sev_wast", "muac_115", "oedema", "sam")
  
  main_table <- get(df_name) %>%
    group_by(Region) %>%
    summarise_prev_table()

  total_row <- summarise_prev_table(get(df_name)) %>%
    mutate(Region = "Total") %>%
    select(Region, everything())
  
  full_table <- bind_rows(main_table, total_row)
  
  # Suppress % if N < 30
  for (var in indicators) {
    pct_col <- paste0(var, " (%)")
    n_col   <- paste0(var, " (N)")
    
    if (pct_col %in% names(full_table) && n_col %in% names(full_table)) {
      mask <- is.na(full_table[[n_col]]) | full_table[[n_col]] < 30
      if (any(mask)) {
        full_table[[pct_col]] <- as.character(full_table[[pct_col]])
        full_table[[pct_col]][mask] <- " - "
      }
    }
  }
  full_table <- replace_names_with_labels(full_table, get(df_name), indicators)
  assign(table_name, full_table)
  # View(get(table_name))
  
  # GAM TABLE
  table_name <- "gam_6_59m"
  df_name <- "df_6_59m"
    indicators <- c("wast", "muac_125", "oedema", "gam")

  main_table <- get(df_name) %>%
    group_by(Region) %>%
    summarise_prev_table()
  
  total_row <- summarise_prev_table(get(df_name)) %>%
    mutate(Region = "Total") %>%
    select(Region, everything())
  
  full_table <- bind_rows(main_table, total_row)
  
  # Suppress % if N < 30
  for (var in indicators) {
    pct_col <- paste0(var, " (%)")
    n_col   <- paste0(var, " (N)")
    
    if (pct_col %in% names(full_table) && n_col %in% names(full_table)) {
      mask <- is.na(full_table[[n_col]]) | full_table[[n_col]] < 30
      if (any(mask)) {
        full_table[[pct_col]] <- as.character(full_table[[pct_col]])
        full_table[[pct_col]][mask] <- " - "
      }
    }
  }
  full_table <- replace_names_with_labels(full_table, get(df_name), indicators)
  assign(table_name, full_table)
  # View(get(table_name))

  # **************************************************************************************************
  # * Anthropometric indicators for children from 0- 59 months
  # **************************************************************************************************
  
  # mod_wast_0_59m TABLE   
  table_name <- "mod_wast_0_59m"
  df_name <- "df"  # Use full dataset of children 0-59M
  indicators <- c("muac_115_119", "sev_uwt", "mod_muac_suwt" ,"muac_115_119_24m", "sev_uwt_24m", "mod_muac_suwt_24m")
  
  main_table <- get(df_name) %>%
    group_by(Region) %>%
    summarise_prev_table()
  
  total_row <- summarise_prev_table(get(df_name)) %>%
    mutate(Region = "Total") %>%
    select(Region, everything())
  
  full_table <- bind_rows(main_table, total_row)
  
  # Suppress % if N < 30 - updated - convert to function and place above
  for (var in indicators) {
    pct_col <- paste0(var, " (%)")
    n_col   <- paste0(var, " (N)")
    
    if (pct_col %in% names(full_table) && n_col %in% names(full_table)) {
      
      # Create mask for low sample size OR variable is all NA
      all_na <- all(is.na(df[[var]]))  # Check the original variable in df
      mask <- is.na(full_table[[n_col]]) | full_table[[n_col]] < 30 | all_na
      
      if (any(mask)) {
        full_table[[pct_col]] <- as.character(full_table[[pct_col]])
        full_table[[pct_col]][mask] <- " - "
      }
    }
  }
  full_table <- replace_names_with_labels(full_table, get(df_name), indicators)
  assign(table_name, full_table)
  # View(get(table_name))
  
  
  # Children 0-59m with Wasting, MUAC, Underweight and Bilateral Oedema (all_0_59m)
  table_name <- "all_0_59m"
  df_name <- "df"  # Use full dataset of children 0-59M
  indicators <- c("wast", "muac_125","oedema", "uwt" )
  
  main_table <- get(df_name) %>%
    group_by(Region) %>%
    summarise_prev_table()
  
  total_row <- summarise_prev_table(get(df_name)) %>%
    mutate(Region = "Total") %>%
    select(Region, everything())
  
  full_table <- bind_rows(main_table, total_row)
  
  # Suppress % if N < 30
  for (var in indicators) {
    pct_col <- paste0(var, " (%)")
    n_col   <- paste0(var, " (N)")
    
    if (pct_col %in% names(full_table) && n_col %in% names(full_table)) {
      mask <- is.na(full_table[[n_col]]) | full_table[[n_col]] < 30
      if (any(mask)) {
        full_table[[pct_col]] <- as.character(full_table[[pct_col]])
        full_table[[pct_col]][mask] <- " - "
      }
    }
  }
  full_table <- replace_names_with_labels(full_table, get(df_name), indicators)
  assign(table_name, full_table)
  # View(get(table_name))
  
  
  # to label all tabs - use cleaned name - Remove everything before the first dash and after -ANT.csv
  cleaned_name <- sub("^[^-]+-", "", file)              # Remove before first dash
  cleaned_name <- sub("-ANT\\.csv$", "", cleaned_name)  # Remove -ANT.csv at end
  print(cleaned_name)
  
  country_name <- df$country[!is.na(df$country)][1]
  survey_name  <- df$survey[!is.na(df$survey)][1]
  survey_year  <- df$year[!is.na(df$year)][1]
  start <- min(df$date_measure, na.rm = TRUE)
  end <- max(df$date_measure, na.rm = TRUE)
  
  # Define file, sheet, and cell position
  file_path <- paste0("C:/Users/rojohnston/Downloads/WHO_indicators_", country_name, ".xlsx")
  sheet_name <- cleaned_name # use 

  if (!file.exists(file_path)) {
    wb <- createWorkbook()
  } else {
    wb <- loadWorkbook(file_path)
    
    if (sheet_name %in% names(wb)) {
      removeWorksheet(wb, sheet_name)  # drop if not clean
    }
  }
  addWorksheet(wb, sheet_name)
  
  x = 2
  y = 5
  add_y = length(unique(df$Region)) +4  # add rows between each pasted table
  
  # Write Country, Survey Type, Start and End Date
  note1 <- paste("Country:", country_name,"   Survey:", survey_name, survey_year)
  note2 <- paste("Survey data collection from", start, "to", end)
  
  writeData(wb, sheet = sheet_name, x = "WHO Guideline 2024 - Indicators for at risk and acute malnutrition", startCol = 2, startRow = 1)
  writeData(wb, sheet = sheet_name, x = note1, startCol = 2, startRow = 2)
  writeData(wb, sheet = sheet_name, x = note2, startCol = 2, startRow = 3)
  
  writeData(wb, sheet = sheet_name, x = "Infants from 0-5m at risk of poor growth and development", startCol = x, startRow = y)
  writeData(wb, sheet = sheet_name, x = at_risk_0_5m, startCol = x, startRow = y+1)
  y = y + add_y
  
  writeData(wb, sheet = sheet_name, x = "Children 6-59m with Severe Acute Malnutrition", startCol = x, startRow = y)
  writeData(wb, sheet = sheet_name, x = sam_6_59m, startCol = x, startRow = y+1)
  y = y + add_y
  
  writeData(wb, sheet = sheet_name, x = "Children 6-59m with Global Acute Malnutrition", startCol = x, startRow = y)
  writeData(wb, sheet = sheet_name, x = gam_6_59m, startCol = x, startRow = y+1)
  y = y + add_y
  
  writeData(wb, sheet = sheet_name, x = "Children 0-59m with Moderate Wasting", startCol = x, startRow = y)
  writeData(wb, sheet = sheet_name, x = mod_wast_0_59m, startCol = x, startRow = y+1)
  y = y + add_y
  
  writeData(wb, sheet = sheet_name, x = "Children 0-59m with Wasting, MUAC, Underweight and Bilateral Oedema", startCol = x, startRow = y)
  writeData(wb, sheet = sheet_name, x = all_0_59m, startCol = x, startRow = y+1)

  
  # add graphs
  
  # WHZ Plot
  if ("whz" %in% names(df) && any(!is.na(df$whz))) { # if whz exists or at least one non missing - continue
    df_clean <- df %>% filter(!is.na(whz), !is.na(Region))
    
    plot_path <- file.path(tempdir(), paste0("whz_plot_", sheet_name, ".png"))
    
    # Create and save WHZ plot
    png(plot_path, width = 1200, height = 800, res = 150)
    whz_plot <- ggplot(df_clean, aes(x = whz)) +
      geom_histogram(aes(y = ..density.. * 100), binwidth = 0.2, fill = "skyblue", color = "white") +
      stat_function(fun = function(x) dnorm(x, mean = 0, sd = 1) * 100,
                    color = "gray", linewidth = 1) +
      facet_wrap(~ Region) +
      scale_y_continuous(name = "Percent Density") +
      scale_x_continuous(name = "WHZ", breaks = seq(-5, 5, by = 1)) +
      labs(title = "WHZ Percent Distribution in children 0–59M by Region") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 0, hjust = 1))
    print(whz_plot)
    dev.off()
    
    if (!file.exists(plot_path) || file.info(plot_path)$size == 0) {
      cat(" WHZ plot image was not saved: ", plot_path)
    }
    
    cat(" Inserting WHZ plot for:", sheet_name, "\n")
    
    insertImage(
      wb,
      sheet = sheet_name,
      file = plot_path,
      startRow = 2,
      startCol = 16,
      width = 8,
      height = 5.33,
      units = "in"
    )
  } else {
    cat("️ No valid 'whz' data found in:", sheet_name, "\n")
  }
  
  # MUAC plot
  if ("muac" %in% names(df) && any(!is.na(df$muac))) {  # if muac exists or at least one non missing - continue
    df_clean <- df %>% filter(!is.na(muac), !is.na(Region))
    
    plot_path <- file.path(tempdir(), paste0("muac_plot_", sheet_name, ".png"))
    
    # Calculate limits for x axis label
    muac_min <- max(60, floor(min(df$muac, na.rm = TRUE) / 10) * 10)  # 60 is min
    muac_max <- min(260, floor(max(df$muac, na.rm = TRUE) / 10) * 10)  # 260 is max
    
    # Create and save MUAC plot
    png(plot_path, width = 1200, height = 800, res = 150)
    muac_plot <- ggplot(df, aes(x = muac)) +
      geom_histogram(aes(y = ..density.. * 100),
                     binwidth = 0.2, fill = "pink", color = "pink") +
      facet_wrap(~ Region) +
      scale_y_continuous(name = "Percent Density") +
      scale_x_continuous(
        name = "MUAC",
        breaks = seq(muac_min, muac_max, by = 10),
        limits = c(muac_min, muac_max)
      ) +
      labs(title = "MUAC Percent Distribution by Region") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 90, hjust = 1)) +
      coord_cartesian(expand = FALSE)
    
    print(muac_plot)
    dev.off()
    
    if (!file.exists(plot_path) || file.info(plot_path)$size == 0) {
      cat(" MUAC plot image was not saved: ", plot_path)
    }
    cat(" Inserting MUAC plot for:", sheet_name, "\n")
    
    insertImage(
      wb,
      sheet = sheet_name,
      file = plot_path,
      startRow = 30,
      startCol = 16,   # Plot below WHZ graph
      width = 8,
      height = 5.33,
      units = "in"
    )
  } else {
    cat("️ No valid 'MUAC' data found in:", sheet_name, "\n")
  }
  
  # Save workbook
  saveWorkbook(wb, file_path, overwrite = TRUE)
  cat(" Saved Excel file to:", file_path, "\n")
  
}


















