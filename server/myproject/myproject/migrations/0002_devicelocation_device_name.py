# Generated by Django 4.2.7 on 2024-11-19 14:45

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('myproject', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='devicelocation',
            name='device_name',
            field=models.CharField(blank=True, max_length=100),
        ),
    ]
