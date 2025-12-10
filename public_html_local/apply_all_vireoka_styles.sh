#!/bin/bash
set -e

# Home
wp vireoka-home apply --page_id=93 --style=F --product="Vireoka Platform" --set_home=1

# Products
wp vireoka-home apply --page_id=54 --style=B --product="Vireoka Product Suite"

# AtmaSphere LLM
wp vireoka-home apply --page_id=53 --style=C --product="AtmaSphere LLM"

# FinOps AI (update ID if needed)
wp vireoka-home apply --page_id=102 --style=D --product="FinOps AI"

# Memoir Studio
wp vireoka-home apply --page_id=103 --style=E --product="Memoir Studio"

# Quantum-Secure Stablecoin
wp vireoka-home apply --page_id=104 --style=F --product="Quantum-Secure Stablecoin"

# About / Blog / Contact
wp vireoka-home apply --page_id=55 --style=A --product="About Vireoka"
wp vireoka-home apply --page_id=56 --style=E --product="Insights & Updates"
wp vireoka-home apply --page_id=57 --style=D --product="Contact Vireoka"
