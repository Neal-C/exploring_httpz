# Exploring httpz

## Tests with curl


All scrolls

```bash
curl --request GET \
  --url 'http://localhost:7000/scroll'
```

Scroll by id (id=8)

```bash
curl --request GET \
  --url 'http://localhost:7000/scroll?id=8'
```