## We need a bunch of constants here to keep things from being totally
## infected with magic numbers.  There are still a lot of references
## to '5' and '16' below.
PROQUINT_CONSONANT <- c("b", "d", "f", "g",
                        "h", "j", "k", "l",
                        "m", "n", "p", "r",
                        "s", "t", "v", "z")
PROQUINT_VOWEL <- c("a", "i", "o", "u")
PROQUINT_POOL <- c(PROQUINT_CONSONANT, PROQUINT_VOWEL)
PROQUINT_WORD <- 2^16 # 65536
PROQUINT_MULT <- c(16 * 4 * 16 * 4,
                   16 * 4 * 16,
                   16 * 4,
                   16,
                   1)
PROQUINT_MOD <- c(PROQUINT_WORD, PROQUINT_MULT[-5L])

PROQUINT_IDX_V <- c(2L, 4L)
PROQUINT_IDX_C <- c(1L, 3L, 5L)

PROQUINT_RE_WORD <- sprintf("[%s][%s][%s][%s][%s]",
                            paste(PROQUINT_CONSONANT, collapse = ""),
                            paste(PROQUINT_VOWEL, collapse = ""),
                            paste(PROQUINT_CONSONANT, collapse = ""),
                            paste(PROQUINT_VOWEL, collapse = ""),
                            paste(PROQUINT_CONSONANT, collapse = ""))
PROQUINT_RE <- sprintf("^%s(-%s)*$", PROQUINT_RE_WORD, PROQUINT_RE_WORD)
PROQUINT_RE1 <- sprintf("^%s$", PROQUINT_RE_WORD)

##' Generate random "proquint" identifiers.  "proquint" stands for
##' PRO-nouncable QUINT-uplets and were described by Daniel Wilkerson
##' in \url{https://arxiv.org/html/0901.4016}.  Each "word" takes one
##' of \eqn{2^16} possibilities.  A four word proquint has a keyspace
##' of \eqn{10^19} possibilities but takes only 23 characters.
##' Proquint identifiers can be interchanged with integers (though
##' this is totally optional); see \code{\link{proquint_to_int}} and
##' the other functions documented on that page.
##'
##' In the abstract of their paper, Wilkerson introduces proquints:
##'
##' "Identifiers (IDs) are pervasive throughout our modern
##' life. We suggest that these IDs would be easier to manage and
##' remember if they were easily readable, spellable, and
##' pronounceable. As a solution to this problem we propose using
##' PRO-nouncable QUINT-uplets of alternating unambiguous consonants
##' and vowels: proquints."
##'
##' @title Generate random proquint identifiers
##' @inheritParams ids
##' @param n_words The number of words for each identifier; each word
##'   has \code{2^16} (65536) possible combinations, a two-word
##'   proquint has \code{2^32} possible combinations and an
##'   \code{k}-word proquint has \code{2^(k * 16)} possible
##'   combinations.
##' @param use_cache Because there are relatively few combinations per
##'   word, and because constructing short strings is relatively
##'   expensive in R, it may be useful to cache all 65536 possible
##'   words.  If \code{TRUE} then the first time that this function is
##'   used all words will be cached and the results used - the first
##'   time may take up to ~1/4 of a second and subsequent calls will
##'   be much faster.  The identifiers selected will not change with
##'   this option (i.e., given a particular random seed, changing this
##'   option will not affect the identifiers randomly selected).
##' @param use_openssl Use openssl for random number generation, with
##'   the primary effect that the identifiers will not be affected by
##'   R's random seed (at a small speed cost).
##' @export
##' @examples
##' # A single, two word, proquint
##' proquint()
##'
##' # Longer identifier:
##' proquint(n_words = 5)
##'
##' # More identifiers
##' proquint(10)
proquint <- function(n = 1, n_words = 2L, use_cache = TRUE,
                     use_openssl = FALSE) {
  ## Consider requiring something sane for 'n_words'?
  if (is.null(n)) {
    force(n_words)
    force(use_cache)
    function(n = 1) {
      proquint(n, n_words, use_cache)
    }
  } else {
    words <- proquint_sample_words(n * n_words, use_cache, use_openssl)
    apply(matrix(words, n_words, n), 2L, paste, collapse = "-")
  }
}

##' Convert to and from proquints.
##'
##' These functions try to be type safe and predictable about what
##' they will and will not return.
##'
##' For \code{proquint_to_int}, because numeric overflow is a
##' possibility, it is important to consider whether a proquint can be
##' meaninfully translated into an integer or a numeric and the
##' functions will throw an error rather than failing in a more
##' insidious way (promoting the type or returning NA).
##'
##' \code{proquint_word_to_int} always retuns an integer vector of the
##' same length as the input.
##'
##' Missing values are allowed; a missing integer representation of a
##' proquint will translate as \code{NA_character_} and a missing
##' proquint will translate as \code{NA_integer_} (if \code{as =
##' "integer"}), \code{NA_real_}, if \code{as = "numeric"} or as
##' \code{NULL} (if \code{as = "bignum"}).
##'
##' Names are always discarded.  Future versions may gain an argument
##' \code{named} with a default of \code{FALSE}, but that setting to
##' \code{TRUE} would preseve names.  Let me know if this would be
##' useful.
##'
##' @rdname proquint_conversion
##' @title Convert to and from proquints
##' @param x An integer (or integer-like) value to convert to a
##'   proquint
##' @param p A character vector representing a proquint
##' @param i An integer representing a single proquint word (in the
##'   range 0:65535)
##' @param w A proquint \emph{word} (five letter string)
##' @inheritParams proquint
##' @export
int_to_proquint <- function(x, use_cache = TRUE) {
  if (length(x) == 0L) {
    return(character(0))
  }
  if (is.numeric(x)) {
    if (anyNA(x)) {
      return(na_recall(x, NA_character_, int_to_proquint, use_cache))
    }
    n_words <- ceiling(log(x + 1L, PROQUINT_WORD))
    if (any(n_words > 1L)) {
      scal <- PROQUINT_WORD^(rsequence(n_words) - 1L)
      idx <- rep(x, n_words) %/% scal %% PROQUINT_WORD
    } else {
      idx <- x
    }
  } else if (is.logical(x) && all(is.na(x))) {
    ## Eww nasty corner case here that turns up because a naked 'NA'
    ## in R is a logical vector.
    return(rep(NA_character_, length(x)))
  } else {
    if (inherits(x, "bignum")) {
      x <- list(x)
    } else if (!is_bignum_list(x)) {
      stop("Invalid type for 'x'")
    }
    is_na <- lengths(x) == 0
    if (any(is_na)) {
      return(na_recall(x, NA_character_, int_to_proquint, use_cache,
                       missing = is_na))
    }
    base <- openssl::bignum(PROQUINT_WORD)
    f <- function(el) {
      n_words <- big_log_ceil(el, PROQUINT_WORD)
      if (n_words == 1L) {
        as_integer_bignum(el)
      } else {
        pow <- rsequence(n_words) - 1L
        vapply(n_words - seq_len(n_words),
               function(pow) as_integer_bignum(el %/% (base^pow) %% base),
               integer(1))
      }
    }
    tmp <- lapply(x, f)
    idx <- unlist(tmp)
    n_words <- lengths(tmp)
  }

  words <- int_to_proquint_word(idx, use_cache, FALSE)

  if (any(n_words > 1L)) {
    ## It might be worth a special case here where all things are the
    ## same length because we can use matrix/apply/paste?
    i <- rep(seq_along(x), n_words)
    res <- as.character(tapply(words, i, paste, collapse = "-"))
  } else {
    res <- words
  }

  res
}

##' @param as The target data type for conversion from proquint.  The
##'   options are \code{integer}, \code{numeric} and \code{bignum}.
##'   The first two will overflow given sufficiently large input -
##'   this will throw an error (overflow is at
##'   \code{.Machine$integer.max} and \code{2 / .Machine$double.eps - 1}
##'   for \code{integer} and \code{numeric} respectively).  For
##'   \code{bignum} this will return a \emph{list} of \code{bignum}
##'   elements \emph{even if \code{p} is of length 1}.
##' @rdname proquint_conversion
##' @export
proquint_to_int <- function(p, as = "numeric", use_cache = TRUE) {
  as <- match.arg(as, c("integer", "numeric", "bignum"))
  if (length(p) == 0L) {
    return(switch(as,
                  integer = integer(0),
                  numeric = numeric(0),
                  bignum = list()))
  }
  if (anyNA(p)) {
    na <- switch(as, integer = NA_integer_, numeric = NA_real_,
                 bignum = list(NULL))
    return(na_recall(p, na, proquint_to_int, as, use_cache))
  }

  if (!is.character(p)) {
    stop("Expected a character vector for 'p'")
  }

  err <- !grepl(PROQUINT_RE, p)
  if (any(err)) {
    stop("Invalid identifier: ",
         paste(sprintf("'%s'", p[err]), collapse = ", "))
  }

  words <- strsplit(p, "-")
  len <- lengths(words)
  idx <- proquint_word_to_int(unlist(words), use_cache, FALSE)

  proquint_combine(idx, len, as)
}

##' @export
##' @rdname proquint_conversion
##' @param validate Validate the range of inputs?  Because these
##'   functions are used internally, they can skip input validation.
##'   You can too if you promise to pass sanitised input in.  If
##'   out-of-range values are passed in and validation is disabled the
##'   behaviour is undefined and subject to change.
proquint_word_to_int <- function(w, use_cache = TRUE, validate = TRUE) {
  if (anyNA(w)) {
    return(na_recall(w, NA_integer_, proquint_word_to_int,
                     use_cache, validate))
  }
  if (validate) {
    err <- !grepl(PROQUINT_RE1, w)
    if (any(err)) {
      stop(sprintf("Invalid proquint word: %s",
                   paste(sprintf("'%s'", w[err]), collapse = ", ")))
    }
  }
  if (use_cache) {
    idx <- match(w, proquint_word_cache()) - 1L
  } else {
    sx <- matrix(unlist(strsplit(unlist(w, use.names = FALSE), NULL)),
                 ncol = 5L, byrow = TRUE)
    i <- array(0L, dim(sx))
    i[, PROQUINT_IDX_C] <-
      match(sx[, PROQUINT_IDX_C], PROQUINT_CONSONANT) - 1L
    i[, PROQUINT_IDX_V] <-
      match(sx[, PROQUINT_IDX_V], PROQUINT_VOWEL) - 1L
    idx <- as.integer(drop(i %*% PROQUINT_MULT))
  }
  idx
}

##' @export
##' @rdname proquint_conversion
int_to_proquint_word <- function(i, use_cache = TRUE, validate = TRUE) {
  if (length(i) == 0) { # avoid some corner cases here
    return(character(0))
  }
  if (anyNA(i)) {
    return(na_recall(i, NA_character_, int_to_proquint_word,
                     use_cache, validate))
  }
  if (validate) {
    if (!is.numeric(i)) {
      stop("Invalid proquint word index (not numeric)")
    }
    err <- i < 0 | i >= PROQUINT_WORD
    if (any(err)) {
      stop(sprintf("Invalid proquint word index (out of range): %s",
                   paste(i[err], collapse = ", ")))
    }
  }
  if (use_cache) {
    word <- proquint_word_cache()[i + 1L]
  } else {
    j <- t(outer(i, PROQUINT_MOD, `%%`)) %/% PROQUINT_MULT
    j[PROQUINT_IDX_V, ] <- j[PROQUINT_IDX_V, ] + 16L
    word <- apply(matrix(PROQUINT_POOL[c(j) + 1L], 5L, length(i)), 2, paste0,
                  collapse = "")
  }
  word
}

## Internal support functions:
proquint_sample_words <- function(n, use_cache = TRUE, use_openssl = FALSE) {
  int_to_proquint_word(rand_i16(n, use_openssl), use_cache)
}

cache <- new.env(parent = emptyenv())
proquint_word_cache <- function() {
  if (is.null(cache$proquint_words)) {
    ## This takes ~0.25s, but would be paid across all words anyway
    idx <- as.matrix(expand.grid(1:16, 17:20, 1:16, 17:20, 1:16))[, 5:1]
    let <- array(PROQUINT_POOL[c(idx)], dim(idx))
    cache$proquint_words <- apply(let, 1, paste, collapse = "")
  }
  cache$proquint_words
}

rsequence <- function(nvec) {
  unlist(lapply(nvec, function(n) rev(seq_len(n))))
}

big_log_ceil <- function(x, base) {
  ret <- 1L
  while (x > base) {
    ret <- ret + 1L
    x <- x %/% base
  }
  ret
}

is_bignum_list <- function(x) {
  is.list(x) && all(vapply(x, function(el)
    inherits(el, "bignum") || is.null(el), logical(1)))
}

## This is a hack until openssl is updated; the development version
## has a new as.integer method that should works nicely.
##
## TODO: before CRAN release, check that this does actually work!  See
## the relevant test in test-proquint.R
as_integer_bignum <- function(x) {
  if (openssl_supports_as_integer()) {
    as.integer(x) # nocov
  } else {
    x <- as.raw(x)
    i <- length(x) - seq_along(x)
    as.integer(sum(256^i * as.integer(x)))
  }
}

openssl_supports_as_integer <- function() {
  if (is.null(cache$openssl_supports_as_integer)) {
    cache$openssl_supports_as_integer <-
      utils::packageVersion("openssl") > "0.9.6"
  }
  cache$openssl_supports_as_integer
}

na_recall <- function(x, na, fun, ..., missing = is.na(x)) {
  ret <- rep(na, length(x))
  i <- !missing
  ret[i] <- fun(x[i], ...)
  ret
}

## This tries to deal with the nastiness of overflowing but keeps most
## of the sausage factory out of the main functions.
proquint_combine <- function(idx, len, as) {
  grp <- rep(seq_along(len), len)

  if (as == "bignum") {
    big_combine1 <- function(x) {
      n <- length(x)
      base <- openssl::bignum(PROQUINT_WORD)
      res <- openssl::bignum(0)
      for (i in seq_along(x)) {
        res <- res + x[[i]] * base^(n - i)
      }
      res
    }
    res <- tapply(idx, grp, big_combine1)
    attributes(res) <- NULL
  } else {
    scal <- PROQUINT_WORD^(rsequence(len) - 1L)
    res <- tapply(scal * idx, rep(seq_along(len), len), sum)
    if (as == "integer") {
      i <- res > .Machine$integer.max
      if (any(i)) {
        stop("Integer overflow: cannot represent proquint as integer")
      }
      res <- as.integer(res)
    } else {
      i <- res >= 2 / .Machine$double.eps
      if (any(i)) {
        stop("Numeric overflow: cannot represent proquint as numeric")
      }
      res <- as.numeric(res)
    }
  }
  res
}

rand_i16 <- function(n, use_openssl = FALSE) {
  if (use_openssl) {
    r <- matrix(as.integer(openssl::rand_bytes(2 * n)), 2)
    r[1L, ] <- r[1L, ] * 256L
    as.integer(colSums(matrix(r, 2)))
  } else {
    sample(PROQUINT_WORD, n, replace = TRUE) - 1L
  }
}
