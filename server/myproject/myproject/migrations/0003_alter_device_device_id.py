# Generated by Django 4.2.7 on 2024-11-19 15:41

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myproject', '0002_devicelocation_device_name'),
    ]

    operations = [
        migrations.AlterField(
            model_name='device',
            name='device_id',
            field=models.CharField(max_length=100),
        ),
    ]
