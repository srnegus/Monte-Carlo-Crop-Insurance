##Monte Carlo Simulation##
##########################
library(ggplot2)

#Generating 2 N(0,1) Draws
draw1 = rnorm(5000, 0, 1)
draw2 = rnorm(5000, 0, 1)

#Imposing Correlation between Draws
L = -0.6
corr = (L*draw1 + (1+L)*draw2)/sqrt(L^2+(1+L)^2)

#Turning First Draw and Correlated Draw into Probabilities
d1_prob = pnorm(draw1)
corr_prob = pnorm(corr)

#Turing First Draw Probabilities to Prices#
###########################################

#ZCZ25
cur_price  = 4.3725
#Time to Maturity
time = 1  + (1/12)
#Implied Volatility
imp_vol =  .2132
sd  = imp_vol*sqrt(time)
prices = qlnorm(d1_prob, log(cur_price), sd)

#Turing Correlated Draw Probabilities to Yield#
###############################################

#Creating Beta Inverse Function
betainv = function(p, alpha, beta, lower, upper) {
  qbeta(p, alpha, beta) * (upper-lower) + lower
}

#Defining Low & High Yield
low = 78
high = 252

#Generating Yields
yields = betainv(corr_prob, 1.7, 0.65, low, high)

#No Hedge#
##########
revenue = prices*yields

data = data.frame(yields,prices,revenue)

ggplot(data, aes(revenue, ..count..)) +
  geom_histogram(fill = "darkgrey", color = "black", alpha = 0.7) +
  ggtitle("Distribution of Revenue") +
  xlab("Revenue ($/acre)") + ylab("Count") +
  geom_vline(xintercept = 856.43, color = "red", size=1) +
  geom_vline(xintercept = quantile(data$revenue, probs = 0.5), linetype = "dashed", color = "black", size=1) +
  geom_vline(xintercept = c(quantile(data$revenue, probs = 0.05) ,quantile(data$revenue, probs = 0.95)), linetype = "dotted", color = "black", size=1) +
  annotate(x=856.43,y=700,label="Breakeven",vjust=2,geom="label") +
  annotate(x=quantile(data$revenue, probs = 0.5),y=600,label="50%",vjust=2,geom="label") +
  annotate(x=quantile(data$revenue, probs = 0.05),y=500,label="Worst 5%",vjust=2,geom="label") +
  annotate(x=quantile(data$revenue, probs = 0.95),y=500,label="Best 5%",vjust=2,geom="label") +
  theme_minimal() + 
  theme(plot.title = element_text(hjust = 0.5))

#Forward Contracting#
#####################
forward_price = 4.4
data$hedged_rev = data$revenue + (forward_price - data$prices)*(.85*mean(data$yields))

ggplot(data, aes(hedged_rev)) +
  geom_histogram(fill = "darkgrey", color = "black", alpha = 0.7) +
  ggtitle("Distribution of Revenue with Forward Contracting") +
  xlab("Revenue ($/acre)") + ylab("Count") +
  geom_vline(xintercept = 856.43, color = "red", size=1) +
  geom_vline(xintercept = quantile(data$hedged_rev, probs = 0.5), linetype = "dashed", color = "black", size=1) +
  geom_vline(xintercept = c(quantile(data$hedged_rev, probs = 0.05) ,quantile(data$hedged_rev, probs = 0.95)), linetype = "dotted", color = "black", size=1) +
  annotate(x=856.43,y=750,label="Breakeven",vjust=2,geom="label") +
  annotate(x=quantile(data$hedged_rev, probs = 0.05),y=500,label="Worst 5%",vjust=2,geom="label") +
  annotate(x=quantile(data$hedged_rev, probs = 0.5),y=600,label="50%",vjust=2,geom="label") +
  annotate(x=quantile(data$hedged_rev, probs = 0.95),y=1000,label="Best 5%",vjust=2,geom="label") +
  theme_minimal() + 
  theme(plot.title = element_text(hjust = 0.5))


#RP Insurance#
##############
coverage  = 0.85
feb_price = mean(prices)

for (i in 1:length(data$prices)){
  data$guarantee[i] = coverage*mean(data$yields)*max(feb_price,data$prices[i])
}

data$indemnity = ifelse(data$revenue<data$guarantee, data$guarantee-data$revenue,0)

rp_value = mean(data$indemnity)

data$rp_net = data$revenue+data$indemnity+(.42*rp_value)

ggplot(data, aes(rp_net)) +
  geom_histogram(fill = "darkgrey", color = "black", alpha = 0.7) +
  ggtitle("Distribution of Revenue with 85% Revenue Protection") +
  xlab("Revenue ($/acre)") + ylab("Count") +
  geom_vline(xintercept = 856.43, color = "red", size=1) +
  geom_vline(xintercept = quantile(data$rp_net, probs = 0.5), linetype = "dashed", color = "black", size=1) +
  geom_vline(xintercept = c(quantile(data$rp_net, probs = 0.05) ,quantile(data$rp_net, probs = 0.95)), linetype = "dotted", color = "black", size=1) +
  annotate(x=856.43,y=550,label="Breakeven",vjust=2,geom="label") +
  annotate(x=quantile(data$rp_net, probs = 0.5),y=600,label="50%",vjust=2,geom="label") +
  annotate(x=quantile(data$rp_net, probs = 0.05),y=700,label="Worst 5%",vjust=2,geom="label") +
  annotate(x=quantile(data$rp_net, probs = 0.95),y=500,label="Best 5%",vjust=2,geom="label") +
  theme_minimal() + 
  theme(plot.title = element_text(hjust = 0.5))


#Forward Contracting + RP#
##########################
data$rp_hedge_net = data$hedged_rev + data$indemnity + (.42*rp_value)
ggplot(data, aes(rp_hedge_net)) +
  geom_histogram(fill = "darkgrey", color = "black", alpha = 0.7) +
  ggtitle("Distribution of Revenue with Forward Contracting and 85% RP") +
  xlab("Revenue ($/acre)") + ylab("Count") +
  geom_vline(xintercept = 856.43, color = "red", size=1) +
  geom_vline(xintercept = quantile(data$rp_hedge_net, probs = 0.5), linetype = "dashed", color = "black", size=1) +
  geom_vline(xintercept = c(quantile(data$rp_hedge_net, probs = 0.05) ,quantile(data$rp_hedge_net, probs = 0.95)), linetype = "dotted", color = "black", size=1) +
  annotate(x=856.43,y=700,label="Breakeven",vjust=2,geom="label") +
  annotate(x=quantile(data$rp_hedge_net, probs = 0.5),y=600,label="50%",vjust=2,geom="label") +
  annotate(x=quantile(data$rp_hedge_net, probs = 0.05),y=600,label="Worst 5%",vjust=2,geom="label") +
  annotate(x=quantile(data$rp_hedge_net, probs = 0.95),y=500,label="Best 5%",vjust=2,geom="label") +
  theme_minimal() + 
  theme(plot.title = element_text(hjust = 0.5))