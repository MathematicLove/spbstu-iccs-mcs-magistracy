fig_dir <- "../report/fig"
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)

# открыть pdf для рисунка (кириллица через cairo)
fig <- function(name, w = 6.5, h = 3.6) {
    cairo_pdf(file.path(fig_dir, paste0(name, ".pdf")),
              width = w, height = h, family = "Times New Roman")
    par(mar = c(4, 4.2, 2.5, 1), mgp = c(2.5, 0.8, 0))
}
hdr <- function(s) cat("\n", s, "\n", sep = "")

res <- list()
keep <- function(name, value) res[[name]] <<- value

x <- c(3.795, 3.434, 3.892, 4.258, 4.814, 4.072, 3.765, 3.647, 4.108, 3.888, 3.576, 4.204, 4.033, 4.388,
       4.319, 3.988, 3.769, 3.997, 4.113, 3.725, 3.968,
       3.595, 4.580, 4.237, 3.382, 4.328, 3.983, 3.915, 3.908, 3.878, 3.957, 4.107, 4.384, 4.454,
       4.219, 4.051, 3.955, 3.762, 3.593, 4.212, 3.894, 3.702,
       3.289, 4.060, 3.921, 4.379, 3.647, 3.994, 4.265, 4.142)
n <- length(x)
al <- 0.05 # alpha_2
c0 <- 3.76; d0 <- 4.12 # отрезок [c, d]
h <- 0.10 # шаг гистограммы
a0 <- 4.00; sig0 <- 0.30 # основная гипотеза
a1 <- 3.60; sig1 <- 0.30 # альтернатива (задание 8)

hdr("1)")
xs <- sort(x)
cat("n =", n, "\n")
print(xs)

# группировка с шагом h, границы кратны h; интервалы вида (l, u]
brk <- round(seq(floor(min(x) / h) * h, ceiling(max(x) / h) * h, by = h), 2)
hs <- hist(x, breaks = brk, plot = FALSE)
grp <- data.frame(LW = brk[-length(brk)], UP = brk[-1], MID = hs$mids,
                  NU = hs$counts, W = hs$counts / n, DENS = hs$density)
print(grp)

# ЭФР вместе с F0 = N(a0, sig0^2)
ef <- ecdf(x)
xx <- seq(3.1, 5.0, length.out = 500)
fig("t1_ecdf")
plot(ef, do.points = FALSE, verticals = FALSE, main = "ecdf(x)", lwd = 1.6,
     xlab = "x", ylab = "Fn(x)", xlim = range(xx), col.01line = "grey70")
points(unique(xs), ef(unique(xs)), pch = 19, cex = 0.45)
lines(xx, pnorm(xx, a0, sig0), col = "firebrick", lwd = 2)
invisible(dev.off())

# гистограмма (высоты nu_i / (n h)) и полигон частот (середины интервалов, замкнут на ось)
pmid <- c(min(hs$mids) - h, hs$mids, max(hs$mids) + h)
pden <- c(0, hs$density, 0)
fig("t1_hist")
plot(hs, freq = FALSE, col = "grey88", border = "grey40", main = "Гистограмма частот", xlab = "x",
     ylab = "v_i / (nh)", xlim = range(xx), ylim = c(0, 2.1), xaxt = "n")
axis(1, at = seq(3.1, 5.0, by = 0.1), labels = FALSE, tcl = -0.25)
axis(1, at = seq(3.2, 4.8, by = 0.2))
lines(pmid, pden, type = "o", pch = 19, cex = 0.5, col = "navy", lwd = 1.5)
lines(xx, dnorm(xx, a0, sig0), col = "firebrick", lwd = 2)
invisible(dev.off())


# Задание 2. Выборочные характеристики
hdr("2)")
m <- mean(x)
s2 <- mean(x^2) - m^2 # выборочная дисперсия
S2 <- n * s2 / (n - 1) # исправленная дисперсия
med <- median(x) # n четное: (x_(25) + x_(26)) / 2
asy <- mean((x - m)^3) / s2^(3/2)
exc <- mean((x - m)^4) / s2^2 - 3
pr <- sum(x >= c0 & x <= d0) / n
cat(sprintf("mean = %.5f  s2 = %.6f  S2 = %.6f  s = %.5f\n", m, s2, S2, sqrt(s2)))
cat(sprintf("x_(25) = %.3f  x_(26) = %.3f  med = %.4f\n", xs[25], xs[26], med))
cat(sprintf("m3 = %.6f  m4 = %.6f  s^3 = %.6f  s^4 = %.6f\n",
            mean((x - m)^3), mean((x - m)^4), s2^(3/2), s2^2))
cat(sprintf("asy = %.4f  exc = %.4f\n", asy, exc))
cat(sprintf("#{c <= X <= d} = %d  P = %.2f\n", sum(x >= c0 & x <= d0), pr))
cat(sprintf("sum x = %.3f  sum x^2 = %.6f\n", sum(x), sum(x^2)))
keep("mean", m); keep("s2", s2); keep("S2", S2); keep("median", med)
keep("asy", asy); keep("exc", exc); keep("prob_cd", pr)

hdr("3)")
a_hat <- m
s2_hat <- s2
bias_a <- 0
bias_s2 <- -s2 / n # E s^2 - sigma^2 = -sigma^2 / n, подставляем s^2
cat(sprintf("a_hat = %.5f  sigma2_hat = %.6f\n", a_hat, s2_hat))
cat(sprintf("bias(a_hat) = 0  bias(sigma2_hat) = -sigma^2/n ~ %.6f\n", bias_s2))
keep("bias_s2", bias_s2)

hdr("4)")
s1 <- sqrt(s2)
ta <- qt(1 - al / 2, n - 1)
da <- s1 * ta / sqrt(n - 1)
xal1 <- qchisq(al / 2, n - 1)
xal2 <- qchisq(al / 2, n - 1, lower.tail = FALSE)
ns2 <- n * s2
CI <- data.frame(PAR = c("a", "sigma^2", "sigma"),
                 LOWER = c(m - da, ns2 / xal2, sqrt(ns2 / xal2)),
                 UPPER = c(m + da, ns2 / xal1, sqrt(ns2 / xal1)))
cat(sprintf("t = %.4f  delta = %.5f  chi2_low = %.4f  chi2_up = %.4f  n s^2 = %.5f\n",
            ta, da, xal1, xal2, ns2))
print(CI, digits = 6)
print(t.test(x, conf.level = 1 - al)$conf.int)
keep("ci_a_lo", CI$LOWER[1]); keep("ci_a_up", CI$UPPER[1])
keep("ci_s2_lo", CI$LOWER[2]); keep("ci_s2_up", CI$UPPER[2])

hdr("5)")
v2 <- (0:(n - 1)) / n # F_n(X_(i) - 0)
v3 <- (1:n) / n # F_n(X_(i))
v4 <- pnorm(xs, a0, sig0) # F_0(X_(i))
v5 <- abs(v2 - v4)
v6 <- abs(v3 - v4)
v7 <- pmax(v5, v6)
Dn <- max(v7)
t.ks <- data.frame(I = 1:n, X = xs, Fn0 = v2, Fn1 = v3, F0 = v4, D1 = v5, D2 = v6, M = v7)
imax <- which.max(v7)
# для отчета: первые 3 строки и 3 строки вокруг максимума
print(t.ks[c(1:3, (imax - 1):(imax + 1)), ], digits = 5)
Dnn <- sqrt(n) * Dn

# D_n и предельное распределение Колмогорова K(x)
pkolm <- function(q, n) stats:::pkolmogorov(q, n)
qkolm <- function(p, n) uniroot(function(q) pkolm(q, n) - p, c(1e-6, 1), tol = 1e-12)$root
# K(x) = sum_{j = -inf}^{inf} (-1)^j exp(-2 j^2 x^2)
pkolm_lim <- function(t) {
    j <- -100:100
    sum((-1)^j * exp(-2 * j^2 * t^2))
}
qkolm_lim <- function(p) uniroot(function(t) pkolm_lim(t) - p, c(0.3, 3), tol = 1e-12)$root

xal_ks <- sqrt(n) * qkolm(1 - al, n) # критическое значение для sqrt(n) D_n
xal_ks_lim <- qkolm_lim(1 - al)
pv_ks <- 1 - pkolm(Dn, n)
pv_ks_lim <- 1 - pkolm_lim(Dnn)
phi_ks <- as.integer(Dnn > xal_ks)
cat(sprintf("D_n = %.5f  sqrt(n) D_n = %.4f\n", Dn, Dnn))
cat(sprintf("x_alpha (точн.) = %.4f  x_alpha (пред.) = %.4f  phi = %d\n", xal_ks, xal_ks_lim, phi_ks))
cat(sprintf("p-value (точн.) = %.4f  p-value (пред.) = %.4f\n", pv_ks, pv_ks_lim))
# ks.test предупреждает о совпадении 3.647 (два раза), на D_n это не влияет
print(suppressWarnings(ks.test(x, "pnorm", a0, sig0)))
keep("Dn", Dn); keep("ks_xal", xal_ks); keep("ks_pv", pv_ks); keep("ks_pv_lim", pv_ks_lim)

hdr("6)")
# объединяем соседние интервалы гистограммы (шаг h) так, чтобы
# интервалов было не более 6 и n p_i >= 5 при H0
brk6 <- c(-Inf, 3.7, 3.9, 4.0, 4.1, 4.3, Inf)
r <- length(brk6) - 1
nu <- as.vector(table(cut(x, brk6, right = TRUE)))
p0 <- pnorm(brk6[2:(r + 1)], a0, sig0) - pnorm(brk6[1:r], a0, sig0)
np0 <- n * p0
res6 <- (nu - np0) / sqrt(np0)
res62 <- res6^2
t.chisq <- data.frame(LW = brk6[1:r], UP = brk6[2:(r + 1)], OBS = nu, P0 = p0, EXP = np0,
                      RES = res6, RES2 = res62)
print(t.chisq, digits = 4)
X2 <- sum(res62)
df6 <- r - 1
xal6 <- qchisq(1 - al, df6)
pv6 <- pchisq(X2, df6, lower.tail = FALSE)
cat(sprintf("X2 = %.4f  df = %d  x_alpha = %.4f  phi = %d  p-value = %.4f\n",
            X2, df6, xal6, as.integer(X2 > xal6), pv6))
print(chisq.test(nu, p = p0))
keep("X2_simple", X2); keep("pv_simple", pv6)

hdr("7)")
# Параметры нельзя подставлять из негруппированной выборки (X, s^2):
# тогда статистика не имеет предельного распределения хи-квадрат(r - 3).
# Берем ту же группировку и считаем статистику как функцию параметра.
# th = (a, sigma), z_i = (u_i - a) / sigma, p_i = Phi(z_i) - Phi(z_{i-1})
pr_grp <- function(th) diff(pnorm(brk6, th[1], th[2]))
chi2_fun <- function(th) {
    p <- pr_grp(th)
    sum((nu - n * p)^2 / (n * p))
}
nll_grp <- function(th) -sum(nu * log(pr_grp(th)))   # минус логарифм группового правдоподобия

# производные p_i по a и sigma:
# dp_i/da = -(phi(z_i) - phi(z_{i-1})) / sigma, dp_i/dsigma = -(z_i phi(z_i) - z_{i-1} phi(z_{i-1})) / sigma
pd <- function(th) {
    z <- (brk6 - th[1]) / th[2]
    zdz <- ifelse(is.finite(z), z * dnorm(z), 0)     # z phi(z) = 0 при z = -inf, +inf
    list(p = diff(pnorm(z)), da = -diff(dnorm(z)) / th[2], ds = -diff(zdz) / th[2])
}
# градиент X2: dX2/dtheta_j = -sum nu_i^2 / (n p_i^2) dp_i/dtheta_j
grad_chi2 <- function(th) {
    d <- pd(th)
    w <- nu^2 / (n * d$p^2)
    c(-sum(w * d$da), -sum(w * d$ds))
}
# градиент -sum nu_i ln p_i: -sum nu_i / p_i dp_i/dtheta_j
grad_nll <- function(th) {
    d <- pd(th)
    w <- nu / d$p
    c(-sum(w * d$da), -sum(w * d$ds))
}

# Градиентный спуск: theta <- theta - eta grad f(theta).
# Если f выросла (или sigma <= 0), шаг eta делим пополам
# (допуск 1e-12: у минимума разности f сравнимы с ошибками округления).
# Остановка, когда длина градиента меньше eps.
grad_desc <- function(f, gr, th, eta = 0.01, eps = 1e-8, maxit = 10000) {
    k <- 0
    repeat {
        g <- gr(th)
        if (sqrt(sum(g^2)) < eps || k >= maxit) break
        th_new <- th - eta * g
        while (th_new[2] <= 0 || f(th_new) > f(th) + 1e-12) {
            eta <- eta / 2
            th_new <- th - eta * g
            if (eta < 1e-12) break
        }
        th <- th_new
        k <- k + 1
        if (k <= 3) cat(sprintf("  итерация %d: a = %.6f  sigma = %.6f  f = %.6f\n", k, th[1], th[2], f(th)))
    }
    cat(sprintf("  итераций %d, шаг eta = %.5f, |grad| = %.1e\n", k, eta, sqrt(sum(g^2))))
    list(par = th, value = f(th), iter = k, eta = eta)
}

# 1) минимизируем хи-квадрат: X2_hat = min_theta X2(theta), старт theta_0 = (mean, s)
cat(sprintf("старт: a = %.5f  sigma = %.5f  X2 = %.6f\n", m, s1, chi2_fun(c(m, s1))))
cat("градиентный спуск для X2(a, sigma):\n")
gd1 <- grad_desc(chi2_fun, grad_chi2, c(m, s1))
a_mc <- gd1$par[1]; sig_mc <- gd1$par[2]; X2_mc <- gd1$value

# проверка: перебор по сетке со сгущением (шаги 0.01, ..., 1e-6):
# считаем f во всех узлах, берем узел с наименьшим значением, вокруг него сетка в 10 раз мельче
grid_min <- function(f, a_lim = c(3.5, 4.5), s_lim = c(0.1, 0.6)) {
    for (step in 10^-(2:6)) {
        ag <- seq(a_lim[1], a_lim[2], by = step)
        sg <- seq(s_lim[1], s_lim[2], by = step)
        val <- outer(ag, sg, Vectorize(function(a, s) f(c(a, s))))
        k <- which(val == min(val), arr.ind = TRUE)[1, ]
        best <- c(ag[k[1]], sg[k[2]], min(val))
        a_lim <- best[1] + c(-2, 2) * step
        s_lim <- best[2] + c(-2, 2) * step
    }
    best
}
gr1 <- grid_min(chi2_fun)
cat(sprintf("проверка сеткой: a = %.6f  sigma = %.6f  X2 = %.6f\n", gr1[1], gr1[2], gr1[3]))

# 2) ОМП по сгруппированным данным тем же спуском: min -sum nu_i ln p_i(theta)
cat("градиентный спуск для ОМП по группам:\n")
gd2 <- grad_desc(nll_grp, grad_nll, c(m, s1))
a_gm <- gd2$par[1]; sig_gm <- gd2$par[2]; X2_gm <- chi2_fun(gd2$par)

df7 <- r - 1 - 2
xal7 <- qchisq(1 - al, df7)
pv7 <- pchisq(X2_mc, df7, lower.tail = FALSE)
pv7g <- pchisq(X2_gm, df7, lower.tail = FALSE)
p_mc <- pr_grp(c(a_mc, sig_mc))
t.chisq7 <- data.frame(LW = brk6[1:r], UP = brk6[2:(r + 1)], OBS = nu, P = p_mc, EXP = n * p_mc,
                       RES = (nu - n * p_mc) / sqrt(n * p_mc), RES2 = (nu - n * p_mc)^2 / (n * p_mc))
print(t.chisq7, digits = 4)
cat(sprintf("мин. хи-квадрат: a = %.5f  sigma = %.5f  sigma^2 = %.6f  X2 = %.4f  p-value = %.4f\n",
            a_mc, sig_mc, sig_mc^2, X2_mc, pv7))
cat(sprintf("ОМП по группам:  a = %.5f  sigma = %.5f  sigma^2 = %.6f  X2 = %.4f  p-value = %.4f\n",
            a_gm, sig_gm, sig_gm^2, X2_gm, pv7g))
cat(sprintf("df = %d  x_alpha = %.4f  phi = %d\n", df7, xal7, as.integer(X2_mc > xal7)))
keep("X2_mc", X2_mc); keep("a_mc", a_mc); keep("sig_mc", sig_mc); keep("pv_mc", pv7)
keep("X2_gm", X2_gm); keep("a_gm", a_gm); keep("sig_gm", sig_gm)

hdr("8)")
# H0: (a, sigma^2) = (a0, sig0^2)  против  H1: (a, sigma^2) = (a1, sig1^2), sig0 = sig1, a1 < a0.
# ln L1/L0 = (a1 - a0)/sig^2 * sum x - n (a1^2 - a0^2)/(2 sig^2) убывает по sum x,
# значит критическая область {mean(X) <= C}, P0(mean(X) <= C) = alpha.
u <- qnorm(1 - al)
C8 <- a0 - u * sig0 / sqrt(n)
pow8 <- pnorm((C8 - a1) * sqrt(n) / sig1)
beta8 <- pnorm((C8 - a1) * sqrt(n) / sig1, lower.tail = FALSE)
phi8 <- as.integer(m <= C8)
pv8 <- pnorm((m - a0) * sqrt(n) / sig0)
cat(sprintf("u = %.4f  C = %.5f  n C = %.4f  mean = %.5f  sum x = %.3f  phi = %d\n",
            u, C8, n * C8, m, sum(x), phi8))
cat(sprintf("Z0 = %.4f  p-value = %.4f  b(phi) = 1 - %.3e\n", (m - a0) * sqrt(n) / sig0, pv8, beta8))

# поменяли местами: H0': (a1, sig1^2) против H1': (a0, sig0^2); область {mean(X) >= C'}
C8b <- a1 + u * sig1 / sqrt(n)
beta8b <- pnorm((C8b - a0) * sqrt(n) / sig0)
pow8b <- 1 - beta8b
phi8b <- as.integer(m >= C8b)
z8b <- (m - a1) * sqrt(n) / sig1
pv8b <- pnorm(z8b, lower.tail = FALSE)
cat(sprintf("C' = %.5f  n C' = %.4f  phi' = %d  Z1 = %.4f  p-value' = %.3e  power' = 1 - %.3e\n",
            C8b, n * C8b, phi8b, z8b, pv8b, beta8b))
cat(sprintf("sqrt(n)(a0 - a1)/sig - u = %.4f\n", sqrt(n) * (a0 - a1) / sig0 - u))
keep("np_C", C8); keep("np_beta", beta8); keep("np_pv", pv8)
keep("np_C2", C8b); keep("np_beta2", beta8b); keep("np_pv2", pv8b)

out <- data.frame(name = names(res), value = sprintf("%.12g", unlist(res)))
write.csv(out, "results_r.csv", row.names = FALSE, quote = FALSE)
cat("\nresults_r.csv\n")