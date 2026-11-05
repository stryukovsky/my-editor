# Gospel readings

The dashboard shows the day's Divine Liturgy Gospel in the Russian Synodal
translation. It uses the computer's local date and the Russian Orthodox
old-style calendar. The movable cycle uses Gauss's Julian Pascha calculation,
the shift after the Exaltation of the Cross, the Sunday of the Forefathers, and
the repeat readings around Theophany. The bundled table covers the regular cycle
and selected fixed feasts and feast-related Saturdays and Sundays. Local
commemorations, supplementary saints' readings, and year-specific service
instructions can add or change passages.

- `lectionary.json` contains verse references extracted from Vadim Bogaiskov's
  calendar under GPL-2.0.
  [Bg Orthodox Calendar 0.13.10](https://downloads.wordpress.org/plugin/bg-orthodox-calendar.0.13.10.zip)
  · [COPYING](COPYING) ·
  [Reading cycle](https://bogaiskov.ru/wp-content/uploads/bg_forreaders/gospel-reading-arithmetic_2077.pdf)
- The four `.text` files contain the public-domain Russian Synodal Gospels. Each
  chapter starts with `#number` and each verse is stored as `number|text`.
  [Ponomar PWA transcription](https://github.com/anttro/ponomar-pwa/tree/3a7f6b05d5f37003f61577433cdb01ba624dca55/static/data/ru/bible/synod)
