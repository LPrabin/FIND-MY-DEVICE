# Generated by Django 4.2.7 on 2024-11-22 02:31

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myproject', '0015_devicelocation_serial_number'),
    ]

    operations = [
        migrations.AddField(
            model_name='device',
            name='serial_number',
            field=models.IntegerField(null=True),
        ),
    ]
