# Description of Project
This program uses Modern Portfolio Theory to optimize a multiple-stock portfolio. The portfolio can consist of any stock that the user desires, provided the stock ticker exists in Yahoo Finance's database. This theory minimizes the risk of a portfolio, given the user’s desired return. The program uses a linear optimizer, which adjusts the weights of each stock to minimize the risk while setting the expected return to the user’s input. The program will output the stock weights, risk, and return characteristics, and some visualizations that aid the user in decision-making.


# Instructions to Replicate Code
## Adjusting Inputs
First, open the file that contains the ".R" file extension in R. Under the `INPUTS` section, adjust the date range. If the tool is used for active portfolio management, the program suggests that the date range ends on the current date.

Next, type the stocks that you want the program to evaluate for your portfolio. Note that the program will get rid of any offending stocks that do not meet your risk/return profile. If you would like to use the S&P 500 as your sample, then "comment out" the line that declares the `stockList` variable and remove the comments from the two lines preceding that declaration.

If you wish to change the risk-free rate, you may do so. Note that the program will read at an annualized rate and convert it to a monthly rate for its evaluation. Additionally, the risk-free rate is assumed constant due to Yahoo Finance removing the U.S. Treasury Bill from their database in recent years.

Next, enter the desired annualized return that you would like to receive in the variable `desiredReturn`. Additionally, enter the amount that you would like to invest as a dollar amount in `dollarsInvested` variable.

## Running the Script
Run the script with echo, and the program will output the optimal weights that you should invest in each stock. Also, the program will return the risk, expected return, and Sharpe ratio of the optimized portfolio. 

## Other Notes
If you want the program to put weights in a greater number of stocks, feel free to change `lines 92-94` to give more constraints to the optimization equation. Here is the [package documentation](https://cran.r-project.org/web/packages/Rglpk/Rglpk.pdf) for `Rglpk`, which optimizes the portfolio in this program.
