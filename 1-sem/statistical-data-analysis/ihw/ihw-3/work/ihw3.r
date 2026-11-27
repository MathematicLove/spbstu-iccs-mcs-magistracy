fig_dir <- "../report/fig"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

fig <- function(name, w = 6.5, h = 3.8) {
    cairo_pdf(file.path(fig_dir, paste0(name, ".pdf")), width = w, height = h, family = "Times New Roman")
    par(mar = c(4, 4.2, 2.5, 1), mgp = c(2.5, 0.8, 0))
}
hdr <- function(s) cat("\n", s, "\n", sep = "")

res_list <- list()
keep <- function(name, value) res_list[[name]] <<- value

y <- c(8.97, 8.99, 9.00, 8.97, 8.97, 8.99, 8.96, 8.98, 9.01, 9.00, 9.00, 8.97, 8.96, 8.98, 8.98, 8.97, 8.99,
       8.99, 8.96, 8.95, 8.99, 9.00, 9.00, 8.99, 8.99, 8.95, 9.01, 8.99, 8.99, 8.97, 8.97, 8.98, 8.97, 8.97,
       8.99, 9.00, 8.97, 8.99, 8.99, 8.97, 8.97, 8.96, 8.99, 9.00, 8.99, 8.99, 8.96, 8.98, 8.97, 8.98)
x <- c(5, 0, 1, 7, 0, 1, 1, 3, 0, 2, 1, 6, 7, 0, 4, 5, 0,
       0, 6, 6, 1, 1, 0, 2, 4, 3, 0, 7, 0, 6, 6, 5, 7, 6,
       2, 2, 2, 2, 7, 5, 1, 5, 4, 6, 2, 3, 4, 6, 7, 5)
dat <- data.frame(Y = y, X = x)
n <- dim(dat)[1]
al <- 0.20    
h <- 0.10     

cat("n =", n, "\n")
print(table(dat$X))
print(round(tapply(dat$Y, dat$X, mean), 4))   # средние Y при каждом X
cat(sprintf("sum X = %g  sum X^2 = %g  sum X^3 = %g  sum X^4 = %g\n", sum(x), sum(x^2), sum(x^3), sum(x^4)))
cat(sprintf("sum Y = %.2f  sum XY = %.2f  sum X^2 Y = %.2f\n", sum(y), sum(x * y), sum(x^2 * y)))
keep("n", n)

draw_data <- function() plot(dat$X, dat$Y, xlab = "X", ylab = "Y", main = "Regression")

# XM - матрица плана p x n, B = (XM XM^T)^-1, bhat = B XM Y
mnk <- function(XM, YM) {
    S <- XM %*% t(XM)
    S1 <- solve(S)
    bhat <- S1 %*% XM %*% YM
    e <- YM - t(XM) %*% bhat
    SSE <- sum(e^2)
    dfe <- n - length(bhat)
    list(S = S, S1 = S1, XY = XM %*% YM, bhat = as.vector(bhat), e = as.vector(e),
         SSE = SSE, dfe = dfe, s2 = SSE / dfe)
}
YM <- as.matrix(dat$Y)

# 1a) Линейная модель Y = b1 + b2 X + e
XM1 <- matrix(c(array(1, dim = n), dat$X), nrow = 2, byrow = TRUE)
f1 <- mnk(XM1, YM)
print(f1$S); print(f1$XY)
cat("bhat =", sprintf("%.7f", f1$bhat), "\n")

Sxx <- sum((x - mean(x))^2); Sxy <- sum((x - mean(x)) * (y - mean(y)))
cat(sprintf("mean X = %.4f  mean Y = %.6f  Sxx = %.4f  Sxy = %.5f  b2 = %.7f\n",
            mean(x), mean(y), Sxx, Sxy, Sxy / Sxx))
cat(sprintf("SSE = %.7f  dfe = %d  s^2 = %.4e  s = %.6f\n", f1$SSE, f1$dfe, f1$s2, sqrt(f1$s2)))
print(f1$S1)
cat("SE(bhat) =", sprintf("%.6f", sqrt(f1$s2 * diag(f1$S1))), "\n")
ql <- lm(Y ~ X, data = dat)          
print(coef(ql)); print(summary(ql)$cov.unscaled)
keep("lin_b1", f1$bhat[1]); keep("lin_b2", f1$bhat[2]); keep("lin_SSE", f1$SSE); keep("lin_s2", f1$s2)
keep("lin_B11", f1$S1[1, 1]); keep("lin_B12", f1$S1[1, 2]); keep("lin_B22", f1$S1[2, 2])

mx <- min(dat$X)
Mx <- max(dat$X)
xl <- c(mx, Mx)
yl <- f1$bhat[1] + f1$bhat[2] * xl
fig("t1a_lin")
draw_data()
points(xl, yl, "l", col = "red", lwd = 2)
invisible(dev.off())

# 1b) Полиномиальная модель Y = b1 + b2 X + b3 X^2 + e
XM2 <- matrix(c(array(1, dim = n), dat$X, dat$X^2), nrow = 3, byrow = TRUE)
f2 <- mnk(XM2, YM)
print(f2$S); print(f2$XY)
cat("bhat =", sprintf("%.8f", f2$bhat), "\n")
cat(sprintf("SSE = %.7f  dfe = %d  s^2 = %.4e  s = %.6f\n", f2$SSE, f2$dfe, f2$s2, sqrt(f2$s2)))
print(f2$S1, digits = 6)
cat("SE(bhat) =", sprintf("%.7f", sqrt(f2$s2 * diag(f2$S1))), "\n")
qs <- lm(Y ~ I(X) + I(X^2), data = dat)   # контроль
print(coef(qs)); print(summary(qs)$cov.unscaled)
keep("q_b1", f2$bhat[1]); keep("q_b2", f2$bhat[2]); keep("q_b3", f2$bhat[3])
keep("q_SSE", f2$SSE); keep("q_s2", f2$s2)

xq <- mx + c(1:1000) / 1000 * (Mx - mx)
yq <- f2$bhat[1] + f2$bhat[2] * xq + f2$bhat[3] * xq^2
fig("t1b_poly")
draw_data()
points(xl, yl, "l", col = "red", lwd = 2)
points(xq, yq, "l", col = "blue", lwd = 2)
invisible(dev.off())

# 1c) H0: e ~ N(0, sig^2), sig > 0
e <- f2$e
s1 <- sqrt(f2$s2)
cat(sprintf("min e = %.5f  max e = %.5f  размах = %.5f\n",
            min(e), max(e), max(e) - min(e), h))
hh <- hist(e, plot = FALSE) # стандартная группировка, шаг 0.01 (с тем что в задание получ. 1 интревал)
print(hh$breaks); print(hh$counts)
brk <- hh$breaks
lb <- length(brk)

# объединяем крайние интервалы, чтобы ожидаемые частоты были не меньше 5
brk <- brk[-c(2, 3, lb - 1)]
lb <- length(brk)
nu <- hist(e, breaks = brk, plot = FALSE)$counts
brk[1] <- -Inf
brk[lb] <- Inf
r <- lb - 1
stopifnot(!any(abs(outer(e, brk[2:(lb - 1)], "-")) < 1e-12))

pr_s <- function(s) pnorm(brk[2:lb], 0, s) - pnorm(brk[1:(lb - 1)], 0, s)
csq.f <- function(s) {
    np <- n * pr_s(s)
    sum((nu - np)^2 / np)
}
# производная X2 по sigma dX2/ds = -sum nu_i^2 / (n p_i^2) dp_i/ds,
# dp_i/ds = -(z_i phi(z_i) - z_{i-1} phi(z_{i-1})) / s,  z = граница / s
dcsq.f <- function(s) {
    z <- brk / s
    zdz <- ifelse(is.finite(z), z * dnorm(z), 0)
    p <- pr_s(s)
    dp <- -diff(zdz) / s
    -sum(nu^2 / (n * p^2) * dp)
}
# градиентный спуск s <- s - eta dX2/ds, при росте X2 шаг делится пополам
eta <- 1e-5
s_cur <- s1
k <- 0
repeat {
    g <- dcsq.f(s_cur)
    if (abs(g) < 1e-8 || k >= 10000) break
    s_new <- s_cur - eta * g
    while (s_new <= 0 || csq.f(s_new) > csq.f(s_cur) + 1e-12) {
        eta <- eta / 2
        s_new <- s_cur - eta * g
        if (eta < 1e-15) break
    }
    s_cur <- s_new
    k <- k + 1
}
stilde <- s_cur
X2 <- csq.f(stilde)
cat(sprintf("Мой любимый градиентный спуск: s = %.6f, iter %d, eta = %.2e, |dX2/ds| = %.1e\n",
            s1, k, eta, abs(dcsq.f(stilde))))
q <- nlm(csq.f, s1)
sg <- seq(0.005, 0.03, by = 1e-6)
cat(sprintf("sigma_tilde = %.6f  X2 = %.4f   (nlm: %.6f, %.4f; сетка: %.6f)\n",
            stilde, X2, q$estimate, q$minimum, sg[which.min(sapply(sg, csq.f))]))

lw <- brk[1:(lb - 1)]
up <- brk[2:lb]
pr <- pr_s(stilde)
ex <- n * pr
res1 <- (nu - ex) / sqrt(ex)
res2 <- res1^2
err.t <- data.frame(lw = lw, up = up, counts = nu, p = pr, exp = ex, res = res1, res2 = res2)
print(err.t, digits = 4)
dfc <- r - 2
xal <- qchisq(al, dfc, lower.tail = FALSE)
pval <- pchisq(X2, dfc, lower.tail = FALSE)
cat(sprintf("r = %d  df = %d  x_alpha = %.4f  phi = %d  p-value = %.4f\n",
            r, dfc, xal, as.integer(X2 > xal), pval))
keep("c_sigma", stilde); keep("c_X2", X2); keep("c_xal", xal); keep("c_pv", pval)

# гистограмма остатков (??? h=0.10 в один интервал попадают)
res <- e
fig("t1c_hist")
hist(res, probability = TRUE, ylim = c(0, 32))
xe <- -0.05 + c(0:1000) / 1000 * 0.1
y1 <- dnorm(xe, 0, s1)
points(xe, y1, "l", col = "blue")
invisible(dev.off())


# 1d) Частные доверительные интервалы для b2 и b3 уровня 1 - alpha
V <- f2$s2 * f2$S1 # оценка ковариационной матрицы bhat
v <- diag(V)
tal <- qt(1 - al / 2, n - 3) # x_alpha = S^-1_{n-3}(1 - alpha/2)
d <- tal * sqrt(v)
t.int <- data.frame(par = c("b2", "b3"), est = f2$bhat[2:3], se = sqrt(v[2:3]), d = d[2:3],
                    lw = f2$bhat[2:3] - d[2:3], up = f2$bhat[2:3] + d[2:3])
cat(sprintf("x_alpha = %.4f\n", tal))
print(t.int, digits = 6)
print(confint(qs, level = 1 - al))  
keep("d_tal", tal)
keep("d_b2_lw", t.int$lw[1]); keep("d_b2_up", t.int$up[1])
keep("d_b3_lw", t.int$lw[2]); keep("d_b3_up", t.int$up[2])

out <- data.frame(name = names(res_list), value = sprintf("%.12g", unlist(res_list)))
write.csv(out, "results_r.csv", row.names = FALSE, quote = FALSE)