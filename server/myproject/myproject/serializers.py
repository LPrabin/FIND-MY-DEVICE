# devicemanager/serializers.py
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import  Device, DeviceLocation

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'password')
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            password=validated_data['password']
        )
        return user



class DeviceSerializer(serializers.ModelSerializer):
    class Meta:
        model = Device
        fields = [
            'id',
            'user',
            'device_id',
            'device_name',
            'rssi',
            'timestamp',
            'latitude',
            'longitude',
            'service_uuids',
            'manufacturer_data',
            'service_data',
            'display_name'
        ]
        read_only_fields = ['user']

class DeviceLocationSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceLocation
        fields = [
            'id',
            'serial_number',
            'device_name',
            'rssi',
            'timestamp',
            'latitude',
            'longitude',
        ]
