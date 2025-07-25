defmodule Fatex.Factory do
  @moduledoc false

  use ExMachina.Ecto, repo: Fatex.Repo

  def bed_factory do
    %Fatex.FatBed{
      name: "John",
      purpose: "purpose",
      description: "descriptive",
      is_active: false
    }
  end

  def doctor_factory do
    %Fatex.FatDoctor{
      name: "John",
      designation: "Surgeon",
      phone: "12345",
      address: "main boulevard",
      email: "test@test.com",
      experience_years: 7,
      rating: 9,
      start_date: DateTime.from_naive!(~N[2017-01-01T00:00:00], "Etc/UTC"),
      end_date: DateTime.from_naive!(~N[2017-01-02T00:00:00], "Etc/UTC")
    }
  end

  def doctor_patient_factory do
    %Fatex.FatDoctorPatient{}
  end

  def hospital_doctor_factory do
    %Fatex.FatHospitalDoctor{}
  end

  def hospital_factory do
    %Fatex.FatHospital{
      name: "St. Mary",
      location: "main boulevard",
      phone: "12345",
      address: "123 street",
      total_staff: 3,
      rating: 5
    }
  end

  def patient_factory do
    %Fatex.FatPatient{
      name: "St. Mary",
      location: "main boulevard",
      phone: "12345",
      address: "123 street",
      prescription: "doses",
      symptoms: "fever",
      date_of_birth: "1994-04-01",
      appointments_count: 4
    }
  end

  def room_factory do
    %Fatex.FatRoom{
      name: "Room 1",
      purpose: "serious patients",
      description: "sensitive",
      is_active: true,
      floor: 3
    }
  end
end
