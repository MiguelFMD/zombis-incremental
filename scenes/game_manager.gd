extends Node

## Moneda actual (zombies sacrificados).
var sacrificed_zombies: int = 0

## Multiplicador de daño de excavación (mejora comprada).
var dig_power_multiplier: float = 1.0

## Se emite cada vez que cambia la moneda.
signal currency_updated(new_amount: int)
