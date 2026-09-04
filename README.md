# Hindsight και LiteLLM

Docker Compose stack με:

- Hindsight Control Plane και API
- LiteLLM gateway
- μία κοινή PostgreSQL εγκατάσταση με ξεχωριστές βάσεις και roles
- Caddy για HTTPS και reverse proxy

Η PostgreSQL και το LiteLLM δεν δημοσιεύουν θύρες στο host. Η εξωτερική πρόσβαση γίνεται αποκλειστικά μέσω του Caddy στις θύρες `80` και `443`.

## Διευθύνσεις

| Υπηρεσία | URL | Εσωτερικός προορισμός |
| --- | --- | --- |
| Hindsight Control Plane | `https://hindsight.custom.gr` | `hindsight:9999` |
| Hindsight API | `https://api.hindsight.custom.gr` | `hindsight:8888` |
| LiteLLM | `https://litellm.custom.gr` | `litellm:4000` |

## Προαπαιτούμενα

- Docker Engine
- Docker Compose v2
- Οι θύρες `80/tcp` και `443/tcp` να είναι προσβάσιμες από το Internet
- DNS `A` ή `AAAA` records για τα τρία domains προς τον server

Το Caddy εκδίδει αυτόματα TLS certificates μόνο αφού τα DNS records δείχνουν στον σωστό server.

## Ρύθμιση

Δημιουργήστε το `.env` με τον interactive generator:

```bash
./generate-env.sh
```

Το script:

- ζητά το OpenRouter API key χωρίς να το εμφανίζει στο terminal,
- ζητά versions και OpenRouter models, προσφέροντας τις τρέχουσες προτεινόμενες τιμές,
- δημιουργεί αυτόματα ισχυρά PostgreSQL passwords και application tokens,
- γράφει ατομικά το `.env` με permissions `600`,
- δεν αντικαθιστά υπάρχον `.env` χωρίς ρητή επιβεβαίωση.

Για χειροκίνητη ρύθμιση:

```bash
cp .env.example .env
```

Στη χειροκίνητη ρύθμιση, αντικαταστήστε όλες τις τιμές `replace-me`. Τα `LITELLM_MASTER_KEY` και `LITELLM_SALT_KEY` πρέπει να αρχίζουν με `sk-`. Το `LITELLM_SALT_KEY` πρέπει να παραμένει σταθερό μετά την πρώτη χρήση, επειδή χρησιμοποιείται για την προστασία αποθηκευμένων credentials.

Το `.env` αγνοείται από το Git. Μην το προσθέσετε στο repository.

## Εκκίνηση

```bash
docker compose pull
docker compose up -d
```

Στην πρώτη εκκίνηση, το `litellm-db-init` δημιουργεί idempotently τη βάση και το role του LiteLLM μέσα στην υπάρχουσα PostgreSQL. Δεν ξεκινά δεύτερο PostgreSQL instance.

Έλεγχος κατάστασης:

```bash
docker compose ps
docker compose logs --tail=100 caddy litellm hindsight postgres
```

Έλεγχος LiteLLM μέσω Caddy:

```bash
curl https://litellm.custom.gr/health/liveliness
```

Authenticated έλεγχος API:

```bash
set -a
. ./.env
set +a
curl \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  https://litellm.custom.gr/v1/models
```

Το LiteLLM UI είναι διαθέσιμο στο:

```text
https://litellm.custom.gr/ui
```

## Καθημερινές εντολές

Ενημέρωση και επανεκκίνηση:

```bash
docker compose pull
docker compose up -d
```

Παρακολούθηση logs:

```bash
docker compose logs -f litellm
docker compose logs -f hindsight
docker compose logs -f caddy
```

Τερματισμός χωρίς διαγραφή δεδομένων:

```bash
docker compose down
```

Το `docker compose down -v` διαγράφει οριστικά τις βάσεις και τα δεδομένα του Caddy. Χρησιμοποιήστε το μόνο όταν θέλετε πλήρη καταστροφή της εγκατάστασης.

## Production checklist

- Αντικαταστήστε όλα τα placeholder secrets.
- Χρησιμοποιήστε μακρά, διαφορετικά passwords και keys.
- Κρατήστε αντίγραφα ασφαλείας του volume `postgres_data`.
- Κρατήστε σταθερό το `LITELLM_SALT_KEY`.
- Κλειδώστε τα `HINDSIGHT_VERSION` και `LITELLM_VERSION` σε συγκεκριμένα release tags αντί για `latest`.
- Επιβεβαιώστε ότι μόνο οι θύρες `80` και `443` δημοσιεύονται από το stack.
