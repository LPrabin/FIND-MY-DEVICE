# Generated by Django 4.2.7 on 2024-11-18 05:28

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='Device',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('device_id', models.CharField(max_length=100, unique=True)),
                ('device_name', models.CharField(blank=True, max_length=100)),
                ('last_seen', models.DateTimeField(auto_now=True)),
                ('rssi', models.IntegerField(null=True)),
                ('timestamp', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'ordering': ['-timestamp'],
            },
        ),
        migrations.CreateModel(
            name='DeviceLocation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('rssi', models.IntegerField()),
                ('latitude', models.FloatField()),
                ('longitude', models.FloatField()),
                ('timestamp', models.DateTimeField()),
                ('service_uuids', models.JSONField(default=list)),
                ('manufacturer_data', models.TextField(blank=True)),
                ('service_data', models.TextField(blank=True)),
                ('device', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, to='myproject.device')),
            ],
            options={
                'ordering': ['-timestamp'],
            },
        ),
    ]