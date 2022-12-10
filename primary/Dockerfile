FROM postgres:14.5-bullseye

RUN apt-get update && apt-get install -y        \
    locales                                     \
    iputils-ping                                \
    net-tools                                   \
&&  locale-gen ja_JP.UTF-8                      \
&&  localedef -i ja_JP -c -f UTF-8 -A /usr/share/locale/locale.alias ja_JP.UTF-8

RUN apt-get update \
    && apt install -y --no-install-recommends curl ca-certificates gnupg \
    && curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/nul \
    && sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg 14" > /etc/apt/sources.list.d/pgdg.list' \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-contrib-14 \
    && rm -rf /var/lib/apt/lists/*

ENV LANG        ja_JP.UTF-8
ENV LC_CTYPE    ja_JP.UTF-8
