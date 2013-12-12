load '../model/resource.rb'
load '../model/booking.rb'
Resource.create(name: "Computadora", description: "Notebook con 4GB de RAM y 256 GB de espacio en disco con Linux")
Resource.create(name: "Monitor", description: "Monitor de 24 pulgadas SAMSUNG")
Resource.create(name: "Sala de reuniones", description: "Sala de reuniones con máquinas y proyector")
Booking.create(start: "2013-11-13 11:00:00", end: "2013-11-13 12:00:00", status: "approved", resource_id: 2, user: "martita@gmail.com")
Booking.create(start: "2013-11-13 14:00:00", end: "2013-11-13 15:00:00", status: "pending", resource_id: 2, user: "martita@gmail.com")
Booking.create(start: "2013-11-14 11:00:00", end: "2013-11-14 12:00:00", status: "approved", resource_id: 2, user: "martita@gmail.com")