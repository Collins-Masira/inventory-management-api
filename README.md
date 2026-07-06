## Git Workflow

Development was split across three feature branches, each opened as its own
pull request into `main`, reviewed, merged, and deleted after merging:

| Branch | What it added |
|---|---|
| `feature/crud-and-routing` | Full CRUD routes, category/low-stock helper routes, and the external API routes |
| `feature/frontend-ui` | The UI (`templates/index.html`): product table, add-product form, external-import button |
| `feature/testing` | The pytest suite (`tests/test_app.py`) |

Workflow used for each feature:

```bash
git checkout main
git pull
git checkout -b feature/<name>
# ...work, commit...
git push -u origin feature/<name>
# Open a Pull Request on GitHub (base: main <- compare: feature/<name>)
# Review, then click "Merge pull request", then "Delete branch"
git checkout main
git pull
```

All three branches were merged in this order — `crud-and-routing` →
`frontend-ui` → `testing` — with no merge conflicts, since each branch
touched a distinct part of the codebase.