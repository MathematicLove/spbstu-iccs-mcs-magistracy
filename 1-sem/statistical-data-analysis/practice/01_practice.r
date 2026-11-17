#d - density
#p - func
#q - quantile
#r - sample

# Grid (step 1/1000) -> 6000 steps -> (-3,3) 
# c() - array
# indexing from 1 
x <- -3 + c(0:1000) / 1000 * 6
# vectorzed calculation
y <- dnorm(x)

plot(x=x, y=y, type="l", main="T2-distribution (pdf)", ylab="PDF", lwd=2)

df <- c(2, 5, 7, 10, 50)
ldf <- length(df)
clr = c("red", "blue", "green", "orange", "magenta")

for (i in 1:ldf) {
    y <- dt(x, df[i])
    points(x, y, type="l", col=clr[i])
}

legend("topleft", legend=c("N(0,1)", paste0("Student ", df, " df")), col=c("black", clr), cex=1, lwd=2)

###
n <- 100
a <- 2
sig <- 4

x <- rnorm(n, a, sig)

# EDF
n <- length(x)

ef <- ecdf(x)
ef(1.35)

plot.ecdf(x, cex=.2, pch=NA, main="Empirical cumulative distribution")

xs <- sort(x)
ys <- c(0:(n - 1))/n

points(xs, ys, cex=.2, pch=19)
# Not in practice
x1 <- -10 + c(0:1000) / 1000 * 30
y <- pnorm(x1, a, sig)
points(x1, y, "l", col="red")

# HIST
hist(x, breaks=7, probability=TRUE)

# Groups 
# brk <- min(x) + c(0:7) / 7 * (max(x) - min(x))
# hist(x, breaks=brk, probability=TRUE)
y <- dnorm(x1, a, sig)
points(x1, y, type="l", col="red", lwd=2)

dn <- density(x)
points(dn, col="green", type="l", lwd=2)

dn1 <- density(x, bw=2)
points(dn1, col="blue", type="l", lwd=2)

### Характеристики
# Asy = E(X-EX)^3 / (DX)^3/2
# Exc = (E(X-EX)^4 / (DX)^2) - 3
# Нужна выборочная дисперсия (не Var, так как это исправленная Ч.Х.)

m <- mean(x)
# m <- sum(x)/length(x)
s2 <- mean(x^2) - m^2

# Можно так:
# s2_ <- (n - 1) * var(x) / n

asy <- mean((x-m)^3) / s2^(3/2)
exc <- (mean((x-m)^4) / s2^2) - 3

# Промежуток (выборочная оценка вероятности)
pr <- sum((x >= 0 & x <= 4))/n