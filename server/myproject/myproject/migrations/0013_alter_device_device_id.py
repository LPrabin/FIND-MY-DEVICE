# Generated by Django 4.2.7 on 2024-11-21 14:03

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myproject', '0012_alter_device_manufacturer_data_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='device',
            name='device_id',
            field=models.CharField(max_length=100),
        ),
    ]
