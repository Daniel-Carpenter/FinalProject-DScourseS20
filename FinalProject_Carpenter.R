# LIBRARY  --------------------------------------------------------------------------------------------------------
  library(tidyverse)
  library(dplyr)
  library(knitr)            # Used to concatenate words
  library(lubridate)        # Used to clean up dates
  library(tidyr)            # Used to pivot data frame
  library(BatchGetSymbols)  # Used to Pull in Stock Data
  library(Rglpk)            # Used to optimize portfolio weights
  library(stargazer)
  library(ggthemes)
  library(xtable)  

# INPUTS  -------------------------------------------------------------------------------------------------------
    startDate     <- Sys.Date() -  365 * 2 # "2020-04-01"
    endDate       <- Sys.Date() 
    
    #df.SP500     <- GetSP500Stocks()
    #stockList    <- df.SP500$Tickers
    stockList     <- c('XLP', 'XLB',  'XLF', 'XLI', 'XLK', 'XLU', 'XLV', 'XLY') # 'XLE',
    riskFreeRate  <- .0160
    desiredReturn       <- 0.075   # e.g. 10% = 0.10
    dollarsInvested     <- 10000

# DATA PULL -----------------------------------------------------------------------------------------------------
  # Make Variables Monthly
    desiredReturn <- desiredReturn / 12

    tBill <- c('^IRX')
    
  # Pull Stock Data
    df <- BatchGetSymbols(tickers = c(tBill, stockList), 
                          first.date = startDate,
                          last.date = endDate, 
                          freq.data = 'monthly',
                          cache.folder = file.path(tempdir(), 'BGS_Cache'))
    
  # Mutate Data (Drop Cols and Rename)
    df <- as.data.frame(df$df.tickers) %>%
      select(ref.date,
             ticker,
             price.adjusted,
             ret.adjusted.prices) %>%
      mutate(ref.date = as.Date(ref.date)) %>%
      rename(date = ref.date) %>%
      rename(stockPrice = price.adjusted) %>%
      rename(stockName = ticker) %>%
      rename(stockReturn = ret.adjusted.prices) %>%
      drop_na()
    
    exampleData <- df %>%
      mutate(date = as.character(date)) %>%
      filter(stockName != '^IRX')
    
    df <- df %>% select(-stockPrice)
    
  # Create Avg. Return Table (by Stock)
    df.return <- as.data.frame(df %>%
      filter(stockName != '^IRX') %>%
      group_by(stockName) %>%
      summarise(avgMonthlyReturn = mean(stockReturn)))
      rownames(df.return) = df.return$stockName
    df.return1 <- df.return
    df.return <- t(data.matrix(df.return %>%
      select(-stockName)))
    
    df.CI <- df %>% #includes only returns
      drop_na() %>%
      filter(stockName != "^IRX")
    
    df    <- pivot_wider(df, 
                      names_from = stockName, 
                      values_from = stockReturn)
    
    # Create Matrix for Var-Cov Matrix Calculation
    df.matrix     <- data.matrix(df %>% 
                                   select(-date) %>%
                                   drop_na())
    
  # Calculate Excess Returns
    df.excess <-  df.matrix[,2:NCOL(df.matrix)] - df.matrix[,1] # Stock Price - mean Stock Price
    
  # Clean up Some Tables for Below Calculatons
    df <- df %>% select(-'^IRX')
    df.matrix     <- data.matrix(df %>% 
                                   select(-date) %>%
                                   drop_na())
    
    stockList <- as.data.frame(stockList) #Needs to be other object on original pull  
    stockList <- t(df.matrix)
    
# MAIN -----------------------------------------------------------------------------------------------------------
  # Create Variance-Covariance Matrix
      VarCovMatrix  <- (t(df.excess) %*% df.excess) / NROW(stockList) # Creates Variance Covariance Matrix
  
  # Optimize Risk, Given desired Expected Return
      objectiveFun      <- rep(1,nrow(VarCovMatrix)) %*% sqrt(VarCovMatrix)
      constraintInputs  <- rbind(rep(1, nrow(VarCovMatrix)), as.vector(df.return))
      direction         <- c("==", ">=")
      constraintValues  <- c(1, desiredReturn)
      
      optimalWeights    <- Rglpk_solve_LP(objectiveFun,
                                          constraintInputs,
                                          direction,
                                          constraintValues,
                                          max = FALSE)
    
      portfolioOptimal <- cbind(as.data.frame(optimalWeights$solution),
                                as.data.frame(optimalWeights$solution) * dollarsInvested)
        colnames(portfolioOptimal)  <- c("Stock Weight", "Dollar Investment")
        rownames(portfolioOptimal)  <- rownames(stockList)

  # Calculate Risk of Porfolio
      risk            <- sqrt(12) * sqrt((t(portfolioOptimal$`Stock Weight`) %*% VarCovMatrix) %*% portfolioOptimal$`Stock Weight`) # Standard Deviation (or volatility) of the portfolio, i.e. risk
      
  # Calculate Expected Return of Portfolio
      expectedReturn  <- 12 * (df.return %*% portfolioOptimal$`Stock Weight`)
  
  # Calculate Sharpe Ratio for Portfolio
      sharpeRatio     <- (expectedReturn - riskFreeRate) / risk 
      
  # Summary Table
      summaryTable <- as.data.frame(rbind(risk,expectedReturn, sharpeRatio))
        colnames(summaryTable)  <- c("Value")
        rownames(summaryTable)  <- c("Risk", "Expected Return", "Sharpe Ratio")
        
      portfolioOptimal <- portfolioOptimal %>% 
                          mutate("Stock Name" = rownames(portfolioOptimal)) %>%
                          select("Stock Name", "Stock Weight", "Dollar Investment") %>%
                          filter(portfolioOptimal[1] > 0) #%>%
        
# CONFIDENCE INTERVALS --------------------------------------------------------------------
      
    df.CI <-  df.CI %>%
              subset(stockName %in% portfolioOptimal$`Stock Name`)
    sampleSize <- nrow(df.CI)
      
    # Worst and Best Returns - 95% Confidence Interval
        alpha   <- 1 - (1 - .95) / 2
        error   <- qnorm(alpha) * risk / sqrt(sampleSize)
        upper   <- expectedReturn + error
        lower   <- expectedReturn - error
        
        bounds  <- as.data.frame(rbind(c(lower, upper),
                         c((1 + lower) * dollarsInvested, (1 + upper) * dollarsInvested)))
        colnames(bounds) <- c("Worst Case", "Best Case")
        rownames(bounds) <- c("Percent", "Dollars")

        
# VISUALIZATIONS --------------------------------------------------------------------------
    # Example Data
      #xtable(exampleData)
      
    # Variance-Covariance Matrix Example
      #xtable(VarCovMatrix)
      
    # Optimized Portfolio Stats
      #xtable(summaryTable)
      #xtable(portfolioOptimal)
      #xtable(bounds)
    
    # Monthly Returns by Stock  
      ggplot(data = exampleData, aes(
        x = date, 
        y = stockReturn,
        color = stockName)) +
        geom_jitter() +
        theme_hc() +
        #facet_grid(rows = vars(stockName)) +
        labs(title = "Stock Returns",
             subtitle = "",
             caption = "Data from Yahoo Finance.",
             tag = "Figure 1",
             x = "Date",
             y = "Monthly Return")

# SUMMARY OUTPUT --------------------------------------------------------------------------
  cat("Total Investment:",dollarsInvested, sep = " ")
  print(portfolioOptimal)
  print(summaryTable)
  print(bounds)
