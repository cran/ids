## ---
## title: "ids"
## author: "Rich FitzJohn"
## date: "`r Sys.Date()`"
## output: rmarkdown::html_vignette
## vignette: >
##   %\VignetteIndexEntry{ids}
##   %\VignetteEngine{knitr::rmarkdown}
##   %\VignetteEncoding{UTF-8}
## ---

##+ echo = FALSE, results = "hide"
knitr::opts_chunk$set(error = FALSE)
human_no <- function(x) {
  s <- log10(floor(x + 1))
  p <- c(0, thousand = 3, million = 6, billion = 9, trillion = 12)
  i <- s > p
  j <- max(which(i))
  str <- names(p)[j]
  if (nzchar(str)) {
    paste(signif(x / 10^p[[j]], 3), str)
  } else {
    as.character(x)
  }
}
set.seed(1)

## The `ids` package provides randomly generated ids in a number of
## different forms with different readability and sizes.

## ## Random bytes

## The `random_id` function generates random identifiers by generating
## `bytes` random bytes and converting to hexadecimal (so each byte
## becomes a pair of characters).  Rather than use R's random number
## stream we use the `openssl` package here.
ids::random_id()

## All `ids` functions take `n` as the first argument to be the number
## of identifiers generated:
ids::random_id(5)

## The default here is 16 bytes, each of which has 256 values (so
## 256^16 = 2^128 = 3.4e38 combinations).  You can make these larger or
## smaller with the `bytes` argument:
ids::random_id(5, 8)

## If `NULL` is provided as `n`, then a generating function is
## returned (all ids functions do this):
f <- ids::random_id(NULL, 8)
f

## This function sets all arguments except for `n`
f()
f(4)

## ## UUIDs

## The above look a lot like UUIDs but they are not actually UUIDs.
## The `uuid` package provides real UUIDs generated with libuuid, and
## the `ids::uuid` function provides an interface to that:
ids::uuid()

## As above, generate more than one UUID:
ids::uuid(4)

## Generate time-based UUIDs:
ids::uuid(4, use_time = TRUE)

## and optionally drop the hyphens:
ids::uuid(5, drop_hyphens = TRUE)

## ## Adjective animal

## Generate (somewhat) human readable identifiers by combining one or
## more adjectives with an animal name.
ids::adjective_animal()

## The list of adjectives and animals comes from
## [gfycat.com](http://gfycat.com), via
## https://github.com/a-type/adjective-adjective-animal

## Generate more than one identifier:
ids::adjective_animal(4)

## Use more than one adjective for very long idenfiers
ids::adjective_animal(4, 3)

##+ echo = FALSE, results = "hide"
n1 <- length(ids:::gfycat_animals)
n2 <- length(ids:::gfycat_adjectives)

## There are `r n1` animal names and `r n2` adjectives so each one you
## add increases the idenfier space by a factor of `r n2`.  So for 1,
## 2, and 3 adjectives there are about `r human_no(n1 * n2)`,
## `r human_no(n1 * n2^2)` and `r human_no(n1 * n2^3)` possible combinations.

## This is a much smaller space than the random identifiers above, but
## these are more readable and memorable.

## Note that here, the random nunbers are coming from R's random
## number stream so are affected by `set.seed()`.

## Because some of the animal and adjective names are very long
## (e.g. a _quasiextraterritorial hexakosioihexekontahexaphobic
## queenalexandrasbirdwingbutterfly_), in order to generate more
## readable/memorable identifiers it may be useful to restrict the
## length.  Pass `max_len` in to do this.
ids::adjective_animal(4, max_len = 6)

## A vector of length 2 here can be used to apply to the adjectives
## and animal respectively:
ids::adjective_animal(20, max_len = c(5, Inf))

## Note that this decreases the pool size and so increases the chance
## of collisions.

## In addition to snake_case, the default, the punctuation between
## words can be changed to:
##
## kebab-case:
ids::adjective_animal(1, 2, style = "kebab")

## dot.case:
ids::adjective_animal(1, 2, style = "dot")

## camel-case:
ids::adjective_animal(1, 2, style = "camel")

## PascalCase:
ids::adjective_animal(1, 2, style = "pascal")

## CONSTANT_CASE (aka SHOUTY_CASE)
ids::adjective_animal(1, 2, style = "constant")

## or with spaces, lower case:
ids::adjective_animal(1, 2, style = "lower")

## UPPER CASE
ids::adjective_animal(1, 2, style = "upper")

## Sentence case
ids::adjective_animal(1, 2, style = "sentence")

## Title Case
ids::adjective_animal(1, 2, style = "title")

## Again, pass `n = NULL` here to create a generating function:
aa3 <- ids::adjective_animal(NULL, 3, style = "kebab", max_len = c(6, 8))

## ...which can be used to generate ids on demand.
aa3()
aa3(4)

## ## Random sentences

## The `sentence` function creates a sentence style identifier.  This
## uses the approach described by Asana on [their
## blog](https://blog.asana.com/2011/09/6-sad-squid-snuggle-softly).
## This approach encodes 32 bits of information (so 2^32 ~= 4 billion
## possibilities) and in theory can be remapped to an integer if you
## really wanted to.
ids::sentence()

## As with `adjective_animal`, the case can be changed:
ids::sentence(2, "dot")

## If you would rather past tense for the verbs, then pass `past = TRUE`:
ids::sentence(4, past = TRUE)

## ## proquints

## "proquints" are an identifier that tries to be information dense
## but still human readable and (somewhat) pronounceable; "proquint"
## stands for *PRO*-nouncable *QUINT*-uplets.  They are introduced in
## https://arxiv.org/html/0901.4016

## `ids` can generate proquints:

ids::proquint(10)

## By default it generates two-word proquints but that can be changed:

ids::proquint(5, 1)
ids::proquint(2, 4)

## Proquints are formed by alternating
## consonant/vowel/consonant/vowel/consonant using a subset of both
## (16 consonants and 4 vowels).  This yields 2^16 (65,536)
## possibilities per word.  Words are always lower case and always
## separated by a hyphen.  So with 4 words there are 2^64 combinations
## in 23 characters.

## Proquints are also useful in that they can be tranlated with
## integers.  The proquint `kapop` has integer value 25258
ids::proquint_to_int("kapop")
ids::int_to_proquint(25258)

## This makes proquints suitable for creating human-pronouncable
## identifers out of things like ip addresses, integer primary keys,
## etc.

## The function `ids::int_to_proquint_word` will translate between
## proquint words and integers (and are vectorised)
w <- ids::int_to_proquint_word(sample(2^16, 10) - 1L)
w

## and `ids::proquint_word_to_int` does the reverse
ids::proquint_word_to_int(w)

## whille `ids::proquint_to_int` and `ids::int_to_proquint` allows
## translation of multi-word proquints.  Overflow is a real
## possibility; the maximum integer representable is only about `r
## human_no(.Machine$integer.max)` and the maximum floating point
## number of accuracy of 1 is about `r human_no(2 /
## .Machine$double.eps)` -- these are big numbers but fairly small
## proquints:
ids::int_to_proquint(.Machine$integer.max - 1)
ids::int_to_proquint(2 / .Machine$double.eps)

## But if you had a 6 word proquint this would not work!
p <- ids::proquint(1, 6)

## Too big for an integer:
##+ error = TRUE
ids::proquint_to_int(p)

## And too big for an numeric number:
##+ error = TRUE
ids::proquint_to_int(p, as = "numeric")

## To allow this, we use `openssl`'s `bignum` support:
ids::proquint_to_int(p, as = "bignum")

## This returns a *list* with one bignum (this is required to allow
## vectorisation).

## ## Roll your own identifiers

## The `ids` functions can build identifiers in the style of
## `adjective_animal` or `sentence`.  It takes as input a list of
## strings.  This works particularly well with the `rcorpora` package
## which includes lists of strings.

## Here is a list of Pokemon names:
pokemon <- tolower(rcorpora::corpora("games/pokemon")$pokemon$name)
length(pokemon)

## ...and here is a list of adjectives
adjectives <- tolower(rcorpora::corpora("words/adjs")$adjs)
length(adjectives)

## So we have a total pool size of about `r human_no(length(adjectives) *
## length(pokemon))`, which is not huge, but it is at least topical.

## To generate one identifier:
ids::ids(1, adjectives, pokemon)

## All the style-changing code is available:
ids::ids(10, adjectives, pokemon, style = "dot")

## Better would be to wrap this so that the constants are not passed
## around the whole time:
adjective_pokemon <- function(n = 1, style = "snake") {
  pokemon <- tolower(rcorpora::corpora("games/pokemon")$pokemon$name)
  adjectives <- tolower(rcorpora::corpora("words/adjs")$adjs)
  ids::ids(n, adjectives, pokemon, style = style)
}

adjective_pokemon(10, "kebab")

## As a second example we can use the word lists in rcorpora to
## generate identifiers in the form `<mood>_<scientist>`, like
## "melancholic_darwin".  These are similar to the names of
## docker containers.

## First the lists of names themselves:
moods <- tolower(rcorpora::corpora("humans/moods")$moods)
scientists <- tolower(rcorpora::corpora("humans/scientists")$scientists)

## Moods include:
sample(moods, 10)

## The scientists names contain spaces which is not going to work for
## us because `ids` won't correctly translate all internal spaces to
## the requested style.
sample(scientists, 10)

## To hack around this we'll just take the last name from the list and
## remove all hyphens:
scientists <- vapply(strsplit(sub("(-|jr\\.$)", "", scientists), " "),
                     tail, character(1), 1)

## Which gives strings that are just letters (though there are a few
## non-ASCII characters here that may cause problems because string
## handling is just a big pile of awful)
sample(scientists, 10)

## With the word lists, create an identifier:
ids::ids(1, moods, scientists)

## Or pass `NULL` for `n` and create a function:
sci_id <- ids::ids(NULL, moods, scientists, style = "kebab")

## which takes just the number of identifiers to generate as an argument
sci_id(10)
