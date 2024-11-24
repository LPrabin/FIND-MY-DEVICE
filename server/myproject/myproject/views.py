from django.http import JsonResponse
from rest_framework import viewsets, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated ,AllowAny
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.db.models import Q
from .models import  Device, DeviceLocation
from .serializers import  DeviceLocationSerializer, DeviceSerializer, UserSerializer

@api_view(['POST'])
@permission_classes([AllowAny])
def register_user(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        user.set_password(request.data['password'])
        user.save()
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': serializer.data
        })
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def login_user(request):
    username = request.data.get('username')
    password = request.data.get('password')
    user = authenticate(username=username, password=password)
    if user:
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': UserSerializer(user).data
        })
    return Response({'error': 'Invalid credentials'}, status=status.HTTP_400_BAD_REQUEST)

class DeviceViewSet(viewsets.ModelViewSet):
    permission_classes = [IsAuthenticated]
    serializer_class = DeviceSerializer

    def get_queryset(self):
        return Device.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

@api_view(['POST'])
@permission_classes([AllowAny])
def upload_device_data(request):
    try:
        device, _ = Device.objects.get_or_create(
            device_id=request.data['device_id'],
            user=request.user if request.user.is_authenticated else None,
            defaults={
                'device_name': request.data.get('device_name', ''),
                'rssi': request.data['rssi'],
                'latitude': request.data['latitude'],
                'longitude': request.data['longitude'],
                'timestamp': request.data['timestamp'],
                'service_uuids': request.data.get('service_uuids', ''),
                'manufacturer_data': request.data.get('manufacturer_data', ''),
                'service_data': request.data.get('service_data', ''),
                'display_name': request.data.get('display_name', '')
            }
        )

        DeviceLocation.objects.create(
            
            device_id=request.data['device_id'],
            device_name=request.data.get('device_name', ''),
            rssi=request.data['rssi'],
            latitude=request.data['latitude'],
            longitude=request.data['longitude'],
            timestamp=request.data['timestamp'],
            user=request.user if request.user.is_authenticated else None
        )

        return Response({'message': 'Device data uploaded successfully'}, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)


@api_view(['POST'])
def trigger_audio(request, device_id):
    try:
        device = Device.objects.get(device_id=device_id, user=request.user)
        # Implement your audio triggering logic here
        return Response({'message': 'Audio triggered successfully'})
    except Device.DoesNotExist:
        return Response({'error': 'Device not found'}, 
                      status=status.HTTP_404_NOT_FOUND)


    


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_device(request):
    try:
        device = Device.objects.create(
            user=request.user,
            device_id=request.data['device_id'],
            device_name=request.data.get('device_name', ''),
            display_name = request.data.get['display_name']
        )
        return Response(DeviceSerializer(device).data, status=status.HTTP_201_CREATED)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_400_BAD_REQUEST)
    
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_devices(request):
    try:
        # Get latest record for each unique device_id using distinct and values
        devices = Device.objects.filter(user=request.user)\
            .order_by('device_id', '-timestamp')\
            .distinct('device_id')\
            .values('device_id', 'device_name')
        
        return Response(devices)
    except Exception as e:
        return Response(
            {'detail': str(e)},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_device_locations(request, device_id,device_name):
    try:
        locations = DeviceLocation.objects.filter(
           Q(device_name=device_name) | Q(device_id=device_id)
         ).order_by('-timestamp')
        print(f"User: {request.user.id}")
        print(f"Device ID: {device_id}")
        print(f"Location count: {locations.count()}")
        
        serializer = DeviceLocationSerializer(locations, many=True)
        
        if not serializer.data:
         return JsonResponse({
            'status': 'success',
            'data': [],
            'message': 'no locations found for this device_id'
        })
        return JsonResponse({
            'status': 'success',
            'data': serializer.data
         })
        
        

    except Exception as e:
        return JsonResponse({
            'status': 'error',
            'message': str(e)
        }, status=500)
