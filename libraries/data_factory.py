"""Synthetic test data for ServeRest.

Two kinds of values are generated, on purpose from two different sources:

* **Content** (names, prices, descriptions) comes from a seeded Faker instance. The seed is
  logged, and ``DATA_SEED`` replays the same content in a later run.
* **Uniqueness tags** (in emails and product names) come from the run ID, the pabot worker ID,
  and a counter. They are never seeded, so a replayed run doesn't collide with records left by
  the original run.
"""

import os
import random
import secrets
import string
from itertools import count

from faker import Faker
from robot.api import logger
from robot.api.deco import keyword, library
from robot.api.types import Secret
from robot.libraries.BuiltIn import BuiltIn, RobotNotRunningError

EMAIL_DOMAIN = "example.com"  # RFC 2606: reserved, and accepted by ServeRest's email validator


@library(scope="GLOBAL", auto_keywords=False)
class DataFactory:

    def __init__(self, locale: str = "pt_BR"):
        self.seed = self._resolve_seed()
        self.run_id = "".join(secrets.choice(string.ascii_lowercase + string.digits) for _ in range(4))
        self._faker = Faker(locale)
        self._faker.seed_instance(self.seed)
        self._random = random.Random(self.seed)
        self._sequence = count(1)

    @keyword
    def log_test_data_context(self):
        """Logs the seed and run ID, so a failing run's data can be traced and replayed."""
        logger.info(
            f"Test data: seed={self.seed} run_id={self.run_id} worker={self._worker_id()} "
            f"(replay content with --variable DATA_SEED:{self.seed})"
        )

    @keyword
    def generate_user(
        self,
        nome: str | None = None,
        email: str | None = None,
        password: Secret | str | None = None,
        administrador: str = "false",
    ) -> dict:
        """Returns a valid ``POST /usuarios`` payload. Any field can be overridden.

        ``administrador`` stays a string ("true"/"false"), as ServeRest requires.
        The password is wrapped in a ``Secret``, so it never shows up in logs.
        """
        return {
            "nome": self._faker.name() if nome is None else nome,
            "email": self.unique_email() if email is None else email,
            "password": self._password(password),
            "administrador": administrador,
        }

    def _password(self, password):
        if isinstance(password, Secret):
            return password
        return Secret(self._faker.password(length=12) if password is None else password)

    @keyword
    def generate_product(
        self,
        nome: str | None = None,
        preco: int | None = None,
        descricao: str | None = None,
        quantidade: int | None = None,
    ) -> dict:
        """Returns a valid ``POST /produtos`` payload. Any field can be overridden.

        The type hints make Robot convert ``preco=100`` to the integer 100. A string price, which
        ServeRest wrongly accepts (DQ-03), has to be set explicitly after generation.
        """
        return {
            "nome": self.unique_product_name() if nome is None else nome,
            "preco": self._random.randint(1, 5000) if preco is None else preco,
            "descricao": self._faker.sentence(nb_words=4).rstrip(".") if descricao is None else descricao,
            "quantidade": 10 if quantidade is None else quantidade,
        }

    @keyword
    def test_email_prefix(self) -> str:
        """Returns the prefix shared by every email generated in this run (this process)."""
        return f"qa.{self.run_id}."

    @keyword
    def cart_items(self, *product_and_quantity) -> list[dict]:
        """Builds the ``produtos`` list of a cart from pairs: ``product_id  quantity  ...``."""
        if len(product_and_quantity) % 2:
            raise ValueError("Cart Items expects pairs of product ID and quantity.")
        pairs = zip(product_and_quantity[::2], product_and_quantity[1::2])
        return [{"idProduto": product_id, "quantidade": int(quantity)} for product_id, quantity in pairs]

    @keyword
    def unique_tag(self) -> str:
        """Returns a short value no other test or worker will use, e.g. ``k7f2w0n014``."""
        return self._unique_tag("")

    @keyword
    def unique_email(self) -> str:
        return f"qa.{self._unique_tag('.')}@{EMAIL_DOMAIN}"

    @keyword
    def unique_product_name(self) -> str:
        words = " ".join(self._faker.words(nb=2)).title()
        return f"{words} {self._unique_tag('')}"

    def _unique_tag(self, separator: str) -> str:
        return separator.join((self.run_id, f"w{self._worker_id()}", f"n{next(self._sequence):03d}"))

    @staticmethod
    def _worker_id() -> str:
        try:
            return str(BuiltIn().get_variable_value("${PABOTEXECUTIONPOOLID}", "0"))
        except RobotNotRunningError:
            return "0"

    @staticmethod
    def _resolve_seed() -> int:
        seed = None
        try:
            seed = BuiltIn().get_variable_value("${DATA_SEED}")
        except RobotNotRunningError:
            pass
        seed = seed or os.getenv("DATA_SEED")
        return int(seed) if seed else secrets.randbelow(10**8)
