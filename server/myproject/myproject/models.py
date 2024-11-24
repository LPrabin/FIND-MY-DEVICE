# models.py
from django.db import models
from django.contrib.auth.models import User 
from django.contrib.auth import get_user_model
from django.conf import settings

class Device(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE,null=True,blank=True)
    serial_number = models.IntegerField(null=True)
    device_id = models.CharField(max_length=100, unique=False)
    device_name = models.CharField(max_length=100, blank=True)
    rssi = models.FloatField()
    latitude = models.FloatField()
    longitude = models.FloatField()
    timestamp = models.DateTimeField()
    service_uuids = models.JSONField(default=list,blank=True,null=True)
    manufacturer_data = models.TextField(blank=True,null=True)
    service_data = models.TextField(blank=True,null=True)
    display_name = models.TextField(blank=True)

    class Meta:
        ordering = ['-timestamp']


    def __str__(self):
        return f"{self.device_name} ({self.device_id})"
    
class DeviceLocation(models.Model):
    serial_number = models.IntegerField(null=True)
    device_id = models.CharField(max_length=100)
    device_name = models.CharField(max_length=100, null=True, blank=True)
    latitude = models.FloatField()
    longitude = models.FloatField()
    rssi = models.IntegerField()
    timestamp = models.DateTimeField()
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='device_locations'
    )

    class Meta:
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['device_id', 'timestamp']),
            models.Index(fields=['user', 'device_id']),
        ]

    def __str__(self):
        return f"{self.device_name or 'Unknown'} ({self.device_id}) at {self.timestamp}"
