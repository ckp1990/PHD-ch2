### SubmitJob.R ###
# Usage: source("Scripts/SubmitJob.R"); submit_job(niter=5000, nburnin=1000, label="my_test")

submit_job <- function(niter = 220000, nburnin = 20000, label = NULL) {
  # 1. Determine Paths
  start_dir <- getwd() # Should be project root
  script_path <- file.path(start_dir, "Scripts", "ControlScript.R")
  
  if(!file.exists(script_path)) {
    stop("Could not find ControlScript.R. Make sure you are in the project root.")
  }
  
  # 2. Set Label
  if(is.null(label)) {
    label <- format(Sys.time(), "%d%b%Y_%H%M%S")
  }
  
  # 3. Define Log File
  log_file <- file.path(start_dir, paste0("job_", label, ".log"))
  
  # 4. Find Rscript
  # Try basic 'Rscript' first, then fall back to common Windows paths if needed
  rscript_cmd <- "Rscript"
  # Optional: logic to find specific R path if expected to fail
  # Using the path found in previous steps for robustness:
  possible_paths <- c(
    "C:/Program Files/R/R-4.5.2/bin/x64/Rscript.exe",
    "C:/Program Files/R/R-4.5.2/bin/Rscript.exe"
  )
  for(p in possible_paths) {
    if(file.exists(p)) {
      rscript_cmd <- p
      break
    }
  }

  # 5. Construct Command
  # Command: Rscript ControlScript.R <niter> <nburnin> <label> > log_file 2>&1
  # Note: On Windows 'wait=FALSE' with system2 generally works for detached processes 
  # but sometimes requires 'start /b' behavior or explicit minimized=TRUE.
  
  job_args <- c(shQuote(script_path), niter, nburnin, shQuote(label))
  
  print(paste("Submitting job:", label))
  print(paste("Iterations:", niter))
  print(paste("Log file:", log_file))
  
  # Using PowerShell Start-Process is often more reliable for detached jobs on Windows
  # Command: Start-Process "Rscript" -ArgumentList "..." -NoNewWindow -RedirectStandardOutput "log"
  
  # Ensure quoted correctly for PowerShell
  # Args list needs to be a single string or comma separated
  arg_str <- paste(job_args, collapse = " ")
  
  # Use single quotes for paths inside the PowerShell command string
  # This avoids issues with spaces when wrapped in double quotes for the system call
  q_log <- paste0("'", log_file, "'")
  q_rscript <- paste0("'", rscript_cmd, "'")
  q_wd <- paste0("'", start_dir, "'")
  
  ps_cmd <- paste0(
    "Start-Process -FilePath ", q_rscript, 
    " -ArgumentList '", arg_str, "'",
    " -WorkingDirectory ", q_wd,
    " -NoNewWindow -RedirectStandardOutput ", q_log, 
    " -RedirectStandardError ", q_log,
    " -PassThru"
  )
  
  print(paste("Executing via PowerShell:", ps_cmd))
  
  # Run the PS command via system
  # We actually want to run this PS command to launch the process
  # system(..., wait=FALSE) works well for launching powershell
  
  # Simplest robust way: 
  full_cmd <- paste0("powershell -Command \"", ps_cmd, "\"")
  
  # Run it
  system(full_cmd, wait = FALSE)
  
  # Since we launched via PS, we might not get the logic PID easily back into R without parsing
  # But Start-Process -PassThru returns it to the PS session. 
  # For now, just returning 0 as indicator of launch.
  
  print(paste("Job started via PowerShell."))
  print("You can monitor the log file to see progress.")
  
  return(list(pid = NA, log = log_file, label = label))
}

# Helper to check the log
check_status <- function(job_info) {
  if(is.character(job_info)) {
    # If user just passes the log path
    log_path <- job_info
  } else {
    log_path <- job_info$log
  }
  
  if(file.exists(log_path)) {
    lines <- readLines(log_path)
    n <- length(lines)
    tail_n <- min(n, 10)
    print(paste("--- Status of", basename(log_path), "---"))
    if(n > 0) {
      writeLines(lines[(n-tail_n+1):n])
    } else {
      print("Log file is empty (starting up...)")
    }
  } else {
    print("Log file not found.")
  }
}
