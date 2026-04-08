setup:
	ansible-galaxy role install -r requirements.yml && ansible-galaxy collection install -r requirements.yml

deploy:
	ansible-playbook playbook.yml -i inventory.ini

.PHONY: deploy setup
